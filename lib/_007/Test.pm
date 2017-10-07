use v6;
use _007;
use _007::Type;
use _007::Object;
use _007::Backend::JavaScript;

use Test;

sub read(Str $ast) is export {
    sub n($type, $op) {
        my $name = wrap($type ~ ":<$op>");
        return create(TYPE<Q::Identifier>, :$name);
    }

    my %q_lookup =
        none           => TYPE<Q::Literal::None>,
        int            => TYPE<Q::Literal::Int>,
        str            => TYPE<Q::Literal::Str>,
        array          => TYPE<Q::Term::Array>,
        dict           => TYPE<Q::Term::Dict>,
        object         => TYPE<Q::Term::Object>,
        regex          => TYPE<Q::Term::Regex>,
        sub            => TYPE<Q::Term::Sub>,
        quasi          => TYPE<Q::Term::Quasi>,

        'prefix:~'     => TYPE<Q::Prefix::Str>,
        'prefix:+'     => TYPE<Q::Prefix::Plus>,
        'prefix:-'     => TYPE<Q::Prefix::Minus>,
        'prefix:^'     => TYPE<Q::Prefix::Upto>,

        'infix:+'      => TYPE<Q::Infix::Addition>,
        'infix:-'      => TYPE<Q::Infix::Subtraction>,
        'infix:*'      => TYPE<Q::Infix::Multiplication>,
        'infix:%'      => TYPE<Q::Infix::Modulo>,
        'infix:%%'     => TYPE<Q::Infix::Divisibility>,
        'infix:~'      => TYPE<Q::Infix::Concat>,
        'infix:x'      => TYPE<Q::Infix::Replicate>,
        'infix:xx'     => TYPE<Q::Infix::ArrayReplicate>,
        'infix:::'     => TYPE<Q::Infix::Cons>,
        'infix:='      => TYPE<Q::Infix::Assignment>,
        'infix:=='     => TYPE<Q::Infix::Eq>,
        'infix:!='     => TYPE<Q::Infix::Ne>,
        'infix:~~'     => TYPE<Q::Infix::TypeMatch>,
        'infix:!~'     => TYPE<Q::Infix::TypeNonMatch>,

        'infix:<='     => TYPE<Q::Infix::Le>,
        'infix:>='     => TYPE<Q::Infix::Ge>,
        'infix:<'      => TYPE<Q::Infix::Lt>,
        'infix:>'      => TYPE<Q::Infix::Gt>,

        'postfix:()'   => TYPE<Q::Postfix::Call>,
        'postfix:[]'   => TYPE<Q::Postfix::Index>,
        'postfix:.'    => TYPE<Q::Postfix::Property>,

        my             => TYPE<Q::Statement::My>,
        stexpr         => TYPE<Q::Statement::Expr>,
        if             => TYPE<Q::Statement::If>,
        stblock        => TYPE<Q::Statement::Block>,
        stsub          => TYPE<Q::Statement::Sub>,
        macro          => TYPE<Q::Statement::Macro>,
        return         => TYPE<Q::Statement::Return>,
        for            => TYPE<Q::Statement::For>,
        while          => TYPE<Q::Statement::While>,
        begin          => TYPE<Q::Statement::BEGIN>,

        identifier     => TYPE<Q::Identifier>,
        block          => TYPE<Q::Block>,
        param          => TYPE<Q::Parameter>,
        property       => TYPE<Q::Property>,

        statementlist  => TYPE<Q::StatementList>,
        parameterlist  => TYPE<Q::ParameterList>,
        argumentlist   => TYPE<Q::ArgumentList>,
        propertylist   => TYPE<Q::PropertyList>,
    ;

    # XXX this is a temporary hack while we're refactoring the type system
    # XXX when the system is limber enough to describe itself, it won't be necessary
    my %qtype-has-just-array = qw<
        Q::Term::Array          1
        Q::PropertyList         1
        Q::TraitList            1
        Q::ParameterList        1
        Q::ArgumentList         1
        Q::StatementList        1
    >;

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
            my @attributes = $qtype.type-chain.reverse.map({ .fields }).flat.map({ .<name> });
            sub check-if-operator() {
                if $qname ~~ /^ [prefix | infix | postfix] ":"/ {
                    # XXX: it stinks that we have to do this
                    my $name = wrap($qname);
                    %arguments<identifier> = create(TYPE<Q::Identifier>, :$name);
                    shift @attributes;  # $.identifier
                }
            }();

            if @attributes == 1 && (%qtype-has-just-array{$qtype.name} :exists) {
                my $aname = @attributes[0];
                %arguments{$aname} = wrap(@rest);
            }
            else {
                die "{+@rest} arguments passed, only {+@attributes} parameters expected for {$qtype.name}"
                    if @rest > @attributes;

                for @attributes.kv -> $i, $attr {
                    #if $attr.build && @rest < @attributes {
                    #    @rest.splice($i, 0, "dummy value to make the indices add up");
                    #    next;
                    #}
                    if $attr eq "traitlist" && @rest < @attributes {
                        @rest.splice($i, 0, "dummy value to make the indices add up");
                        next;
                    }
                    %arguments{$attr} = @rest[$i] // last;
                }
            }
            # XXX: these exceptions can go away once we support initializers
            if $qtype === TYPE<Q::Block> {
                %arguments<static-lexpad> //= wrap({});
            }
            if $qtype === TYPE<Q::Statement::Sub> | TYPE<Q::Statement::Macro> | TYPE<Q::Term::Sub> {
                %arguments<traitlist> //= create(TYPE<Q::TraitList>,
                    :traits(wrap([])),
                );
            }
            if $qtype === TYPE<Q::Statement::My> {
                %arguments<expr> //= NONE;
            }
            if $qtype === TYPE<Q::Statement::If> {
                %arguments<else> //= NONE;
            }
            if $qtype === TYPE<Q::Statement::Return> {
                %arguments<expr> //= NONE;
            }
            make create($qtype, |%arguments);
        }
        method expr:symbol ($/) { make ~$/ }
        method expr:int ($/) { make wrap(+$/) }
        method expr:str ($/) { make wrap((~$0).subst(q[\\"], q["], :g)) }
    };

    AST::Syntax.parse($ast, :$actions)
        or die "couldn't parse AST syntax";
    return create(TYPE<Q::CompUnit>, :block(create(TYPE<Q::Block>,
        :parameterlist(create(TYPE<Q::ParameterList>,
            :parameters(wrap([])),
        )),
        :statementlist($/.ast),
        :static-lexpad(wrap({})),
    )));
}

my class StrOutput {
    has $.result = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

my class UnwantedOutput {
    method flush() { die "Program flushed; was not expected to print anything" }
    method print($s) { die "Program printed '$s'; was not expected to print anything" }
}

sub check(_007::Object $ast, $runtime) is export {
    my %*assigned;

    sub handle($ast) {
        if $ast.is-a("Q::StatementList") -> $statementlist {
            for $statementlist.properties<statements>.value -> $statement {
                handle($statement);
            }
        }
        elsif $ast.is-a("Q::Statement::My") -> $my {
            my $symbol = $my.properties<identifier>.properties<name>.value;
            my $block = $runtime.current-frame();
            die X::Redeclaration.new(:$symbol)
                if $runtime.declared-locally($symbol);
            die X::Redeclaration::Outer.new(:$symbol)
                if %*assigned{$block.id ~ $symbol};
            $runtime.declare-var($my.properties<identifier>);

            if $my.properties<expr> !=== NONE {
                handle($my.properties<expr>);
            }
        }
        elsif $ast.is-a("Q::Statement::Constant") -> $constant {
            my $symbol = $constant.properties<identifier>.properties<name>.value;
            my $block = $runtime.current-frame();
            die X::Redeclaration.new(:$symbol)
                if $runtime.declared-locally($symbol);
            die X::Redeclaration::Outer.new(:$symbol)
                if %*assigned{$block.id ~ $symbol};
            $runtime.declare-var($constant.properties<identifier>);

            handle($constant.expr);
        }
        elsif $ast.is-a("Q::Statement::Block") -> $block {
            $runtime.enter(
                $runtime.current-frame,
                $block.properties<block>.properties<static-lexpad>,
                $block.properties<block>.properties<statementlist>);
            handle($block.properties<block>.properties<statementlist>);
            $block.properties<block>.properties<static-lexpad> = $runtime.current-frame.value<pad>;
            $runtime.leave();
        }
        elsif $ast.is-a("Q::Statement::Sub") -> $sub {
            my $outer-frame = $runtime.current-frame;
            my $name = $sub.properties<identifier>.properties<name>;
            my $val = create(TYPE<Sub>,
                :$name,
                :parameterlist($sub.properties<block>.properties<parameterlist>),
                :statementlist($sub.properties<block>.properties<statementlist>),
                :$outer-frame,
                :static-lexpad(wrap({})),
            );
            $runtime.enter($outer-frame, wrap({}), $sub.properties<block>.properties<statementlist>, $val);
            handle($sub.properties<block>);
            $runtime.leave();

            $runtime.declare-var($sub.properties<identifier>, $val);
        }
        elsif $ast.is-a("Q::Statement::Macro") -> $macro {
            my $outer-frame = $runtime.current-frame;
            my $name = $macro.properties<identifier>.properties<name>;
            my $val = create(TYPE<Macro>,
                :$name,
                :parameterlist($macro.properties<block>.properties<parameterlist>),
                :statementlist($macro.properties<block>.properties<statementlist>),
                :$outer-frame,
                :static-lexpad(wrap({})),
            );
            $runtime.enter($outer-frame, wrap({}), $macro.properties<block>.properties<statementlist>, $val);
            handle($macro.properties<block>);
            $runtime.leave();

            $runtime.declare-var($macro.properties<identifier>, $val);
        }
        elsif $ast.is-a("Q::Statement::If") -> $if {
            handle($if.properties<block>);
        }
        elsif $ast.is-a("Q::Statement::For") -> $for {
            handle($for.properties<block>);
        }
        elsif $ast.is-a("Q::Statement::While") -> $while {
            handle($while.properties<block>);
        }
        elsif $ast.is-a("Q::Block") -> $block {
            $runtime.enter($runtime.current-frame, wrap({}), create(TYPE<Q::StatementList>,
                :statements(wrap([])),
            ));
            handle($block.properties<parameterlist>);
            handle($block.properties<statementlist>);
            $block.properties<static-lexpad> = $runtime.current-frame.value<pad>;
            $runtime.leave();
        }
        elsif $ast.is-a("Q::Term::Object") -> $object {
            handle($object.properties<propertylist>);
        }
        elsif $ast.is-a("Q::Term::Dict") -> $object {
            handle($object.properties<propertylist>);
        }
        elsif $ast.is-a("Q::PropertyList") -> $propertylist {
            my %seen;
            for $propertylist.properties<properties>.value -> _007::Object $p {
                my Str $property = $p.properties<key>.value;
                die X::Property::Duplicate.new(:$property)
                    if %seen{$property}++;
            }
        }
        elsif $ast.is-a("Q::ParameterList") || $ast.is-a("Q::Statement::Return") || $ast.is-a("Q::Statement::Expr")
            || $ast.is-a("Q::Statement::BEGIN") || $ast.is-a("Q::Literal") || $ast.is-a("Q::Term")
            || $ast.is-a("Q::Postfix") {
            # we don't care about descending into these
        }
        else {
            die "Don't know how to handle type {$ast.type}";
        }
    }

    handle($ast);
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

sub parses-to($program, $expected, $desc = "MISSING TEST DESCRIPTION", Bool :$unexpanded) is export {
    my $expected-ast = read($expected);
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $actual-ast = $parser.parse($program, :$unexpanded);

    empty-diff stringify($expected-ast, $runtime), stringify($actual-ast, $runtime), $desc;
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

sub runtime-error($program, $expected-error, $desc = $expected-error.^name) is export {
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    {
        $runtime.run($ast);

        CATCH {
            when $expected-error {
                pass $desc;
            }
            default {
                is .^name, $expected-error.^name, $desc;   # which we know will flunk
                return;
            }
        }

        is "no error", $expected-error.^name, $desc;
    }
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

sub emits-js($program, @expected-builtins, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    my $emitted-js = _007::Backend::JavaScript.new.emit($ast);
    my $actual = $emitted-js ~~ /^^ '(() => { // main program' \n ([<!before '})();'> \N+ [\n|$$]]*)/
        ?? (~$0).indent(*)
        !! $emitted-js;
    my @actual-builtins = $emitted-js.comb(/^^ "function " <(<-[(]>+)>/);

    empty-diff @expected-builtins.sort.join("\n"), @actual-builtins.sort.join("\n"), "$desc (builtins)";
    empty-diff $expected, $actual, $desc;
}

sub run-and-collect-output($filepath, :$input = $*IN) is export {
    my $program = slurp($filepath);
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$input, :$output);
    my $ast = _007.parser(:$runtime).parse($program);
    $runtime.run($ast);

    return $output.result.lines;
}

sub run-and-collect-error-message($filepath) is export {
    my $program = slurp($filepath);
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $ast = _007.parser(:$runtime).parse($program);
    $runtime.run($ast);

    CATCH {
        return .message;
    }
}

sub ensure-feature-flag($flag) is export {
    my $envvar = "FLAG_007_{$flag}";
    unless %*ENV{$envvar} {
        skip("$envvar is not enabled", 1);
        done-testing;
        exit 0;
    }
}

sub find($dir, Regex $pattern) is export {
    my @targets = dir($dir);
    my @files;
    while @targets {
        my $file = @targets.shift;
        push @files, $file if $file ~~ $pattern;
        if $file.IO ~~ :d {
            @targets.append: dir($file);
        }
    }
    return @files;
}

our sub EXPORT(*@things) {
    my %exports;
    for @things -> $thing {
        my $routine = EXPORT::ALL::{$thing} // die "Didn't find '$thing'";
        %exports{$thing} = $routine;
    }
    return %exports;
}
