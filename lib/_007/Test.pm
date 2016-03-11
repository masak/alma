use v6;
use _007;
use Test;

sub read(Str $ast) is export {
    sub n($type, $op) {
        Q::Identifier.new(:name(Val::Str.new(:value($type ~ ":<$op>"))));
    }

    my %q_lookup =
        none           => Q::Literal::None,
        int            => Q::Literal::Int,
        str            => Q::Literal::Str,
        array          => Q::Term::Array,
        object         => Q::Term::Object,
        sub            => Q::Term::Sub,

        'prefix:<->'   => Q::Prefix::Minus,
        'prefix:<^>'   => Q::Prefix::Upto,

        'infix:<+>'    => Q::Infix::Addition,
        'infix:<->'    => Q::Infix::Subtraction,
        'infix:<*>'    => Q::Infix::Multiplication,
        'infix:<~>'    => Q::Infix::Concat,
        'infix:<x>'    => Q::Infix::Replicate,
        'infix:<xx>'   => Q::Infix::ArrayReplicate,
        'infix:<::>'   => Q::Infix::Cons,
        'infix:<=>'    => Q::Infix::Assignment,
        'infix:<==>'   => Q::Infix::Eq,
        'infix:<!=>'   => Q::Infix::Ne,
        'infix:<~~>'   => Q::Infix::TypeEq,

        'infix:<<=>'   => Q::Infix::Le,
        'infix:<>=>'   => Q::Infix::Ge,
        'infix:<<>'    => Q::Infix::Lt,
        'infix:<>>'    => Q::Infix::Gt,

        'postfix:<()>' => Q::Postfix::Call,
        'postfix:<[]>' => Q::Postfix::Index,
        'postfix:<.>'  => Q::Postfix::Property,

        my             => Q::Statement::My,
        stexpr         => Q::Statement::Expr,
        if             => Q::Statement::If,
        stblock        => Q::Statement::Block,
        stsub          => Q::Statement::Sub,
        macro          => Q::Statement::Macro,
        return         => Q::Statement::Return,
        for            => Q::Statement::For,
        while          => Q::Statement::While,
        begin          => Q::Statement::BEGIN,

        identifier     => Q::Identifier,
        block          => Q::Block,
        param          => Q::Parameter,
        property       => Q::Property,

        statementlist  => Q::StatementList,
        parameterlist  => Q::ParameterList,
        argumentlist   => Q::ArgumentList,
        propertylist   => Q::PropertyList,
    ;

    my grammar AST::Syntax {
        regex TOP { \s* <expr> \s* }
        proto token expr {*}
        token expr:list { '(' ~ ')' [<expr>+ % \s+] }
        token expr:int { \d+ }
        token expr:str { '"' ~ '"' ([<-["]> | '\\"']*) }
        token expr:symbol { <!before '"'><!before \d> ['()' || <!before ')'> \S]+ }
    }

    my $actions = role {
        method TOP($/) {
            make $<expr>.ast;
        }
        method expr:list ($/) {
            my $qname = ~$<expr>[0];
            die "Unknown name: $qname"
                unless %q_lookup{$qname} :exists;
            my @rest = $<expr>».ast[1..*];
            my $qtype = %q_lookup{$qname};
            my %arguments;
            my @attributes = $qtype.attributes;
            sub check-if-operator() {
                if $qname ~~ /^ [prefix | infix | postfix] ":"/ {
                    # XXX: it stinks that we have to do this
                    %arguments<identifier> = Q::Identifier.new(:name(Val::Str.new(:value($qname))));
                    shift @attributes;  # $.identifier
                }
            }();
            sub aname($attr) { $attr.name.substr(2) }

            if @attributes == 1 && @attributes[0].type ~~ Val::Array {
                my $aname = aname(@attributes[0]);
                %arguments{$aname} = Val::Array.new(:elements(@rest));
            }
            else {
                die "{+@rest} arguments passed, only {+@attributes} parameters expected for {$qtype.^name}"
                    if @rest > @attributes;

                for @attributes.kv -> $i, $attr {
                    if $attr.build && @rest < @attributes {
                        @rest.splice($i, 0, "dummy value to make the indices add up");
                        next;
                    }
                    my $aname = aname($attr);
                    %arguments{$aname} = @rest[$i] // last;
                }
            }
            make $qtype.new(|%arguments);
        }
        method expr:symbol ($/) { make ~$/ }
        method expr:int ($/) { make Val::Int.new(:value(+$/)) }
        method expr:str ($/) { make Val::Str.new(:value((~$0).subst(q[\\"], q["], :g))) }
    };

    AST::Syntax.parse($ast, :$actions)
        or die "couldn't parse AST syntax";
    return Q::CompUnit.new(:block(Q::Block.new(
        :parameterlist(Q::ParameterList.new()),
        :statementlist($/.ast)
    )));
}

class StrOutput {
    has $.result = "";

    method say($s) { $!result ~= $s.gist ~ "\n" }
}

class UnwantedOutput {
    method say($s) { die "Program printed '$s'; was not expected to print anything" }
}

sub check(Q::CompUnit $ast, $runtime) {
    my %*assigned;
    handle($ast);

    # a bunch of nodes we don't care about descending into
    multi handle(Q::ParameterList $) {}
    multi handle(Q::Statement::Return $) {}
    multi handle(Q::Statement::Expr $) {}
    multi handle(Q::Statement::BEGIN $) {}
    multi handle(Q::Literal $) {}
    multi handle(Q::Term $) {} # except Q::Term::Object, see below
    multi handle(Q::Postfix $) {}

    multi handle(Q::StatementList $statementlist) {
        for $statementlist.statements.elements -> $statement {
            handle($statement);
        }
    }

    multi handle(Q::Statement::My $my) {
        my $symbol = $my.identifier.name.value;
        my $block = $runtime.current-frame();
        die X::Redeclaration.new(:$symbol)
            if $runtime.declared-locally($symbol);
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$block ~ $symbol};
        $runtime.declare-var($my.identifier);

        if $my.expr !~~ Val::None {
            handle($my.expr);
        }
    }

    multi handle(Q::Statement::Constant $constant) {
        my $symbol = $constant.identifier.name.value;
        my $block = $runtime.current-frame();
        die X::Redeclaration.new(:$symbol)
            if $runtime.declared-locally($symbol);
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$block ~ $symbol};
        $runtime.declare-var($symbol);

        handle($constant.expr);
    }

    multi handle(Q::Statement::Block $block) {
        $runtime.enter($block.block.eval($runtime));
        handle($block.block.statementlist);
        $block.block.static-lexpad = $runtime.current-frame.pad;
        $runtime.leave();
    }

    multi handle(Q::Statement::Sub $sub) {
        my $outer-frame = $runtime.current-frame;
        my $name = $sub.identifier.name.value;
        my $val = Val::Sub.new(:$name,
            :parameterlist($sub.block.parameterlist),
            :statementlist($sub.block.statementlist),
            :$outer-frame
        );
        $runtime.enter($val);
        handle($sub.block);
        $runtime.leave();

        $runtime.declare-var($sub.identifier, $val);
    }

    multi handle(Q::Statement::Macro $macro) {
        my $outer-frame = $runtime.current-frame;
        my $name = $macro.identifier.name.value;
        my $val = Val::Macro.new(:$name,
            :parameterlist($macro.block.parameterlist),
            :statementlist($macro.block.statementlist),
            :$outer-frame
        );
        $runtime.enter($val);
        handle($macro.block);
        $runtime.leave();

        $runtime.declare-var($macro.identifier, $val);
    }

    multi handle(Q::Statement::If $if) {
        handle($if.block);
    }

    multi handle(Q::Statement::For $for) {
        handle($for.block);
    }

    multi handle(Q::Statement::While $while) {
        handle($while.block);
    }

    multi handle(Q::Block $block) {
        my $valblock = Val::Block.new(
            :parameterlist(Q::ParameterList.new),
            :statementlist(Q::StatementList.new),
            :outer-frame($runtime.current-frame));
        $runtime.enter($valblock);
        handle($block.parameterlist);
        handle($block.statementlist);
        $block.static-lexpad = $runtime.current-frame.pad;
        $runtime.leave();
    }

    multi handle(Q::Term::Object $object) {
        handle($object.propertylist);
    }

    multi handle(Q::PropertyList $propertylist) {
        my %seen;
        for $propertylist.properties.elements -> Q::Property $p {
            my Str $property = $p.key.value;
            die X::Property::Duplicate.new(:$property)
                if %seen{$property}++;
        }
    }
}

sub is-result($input, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $ast = read($input);
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    check($ast, $runtime);
    $runtime.run($ast);

    is $output.result, $expected, $desc;
}

sub is-error($input, $expected-error, $desc = $expected-error.^name) is export {
    my $ast = read($input);
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    check($ast, $runtime);
    $runtime.run($ast);

    CATCH {
        when $expected-error {
            pass $desc;
        }
    }
    flunk $desc;
}

sub empty-diff($text1 is copy, $text2 is copy, $desc) {
    s/<!after \n> $/\n/ for $text1, $text2;  # get rid of "no newline" warnings
    spurt("/tmp/t1", $text1);
    spurt("/tmp/t2", $text2);
    my $diff = qx[diff -U2 /tmp/t1 /tmp/t2];
    $diff.=subst(/^\N+\n\N+\n/, '');  # remove uninformative headers
    is $diff, "", $desc;
}

sub parses-to($program, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $expected-ast = read($expected);
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $actual-ast = $parser.parse($program);
    my %*stringification-seen;

    empty-diff ~$expected-ast, ~$actual-ast, $desc;
}

sub parse-error($program, $expected-error, $desc = $expected-error.^name) is export {
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    $parser.parse($program);

    CATCH {
        when $expected-error {
            pass $desc;
        }
        default {
            is .^name, $expected-error.^name, $desc;   # which we know will flunk
            return;
        }
    }
    flunk $desc;
}

sub outputs($program, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    is $output.result, $expected, $desc;
}

sub throws-exception($program, $message, $desc = "MISSING TEST DESCRIPTION") is export {
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    CATCH {
        when X::_007::RuntimeException {
            is .message, $message, "passing the right Exception's message";
            pass $desc;
        }
    }

    flunk $desc;
}
