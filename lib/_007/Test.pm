use v6;
use _007;
use Test;

sub read(Str $ast) is export {
    my %q_lookup =
        none           => -> { Q::Literal::None.new },
        int            => -> $value { Q::Literal::Int.new(:$value) },
        str            => -> $value { Q::Literal::Str.new(:$value) },
        array          => -> *@elements { Q::Term::Array.new(:elements(Val::Array.new(:@elements))) },
        object         => -> $type, $propertylist { Q::Term::Object.new(:$type, :$propertylist) },

        'prefix:<->'   => -> $expr { Q::Prefix::Minus.new(:$expr) },

        'infix:<+>'    => -> $lhs, $rhs { Q::Infix::Addition.new(:$lhs, :$rhs) },
        'infix:<->'    => -> $lhs, $rhs { Q::Infix::Subtraction.new(:$lhs, :$rhs) },
        'infix:<*>'    => -> $lhs, $rhs { Q::Infix::Multiplication.new(:$lhs, :$rhs) },
        'infix:<~>'    => -> $lhs, $rhs { Q::Infix::Concat.new(:$lhs, :$rhs) },
        'infix:<=>'    => -> $lhs, $rhs { Q::Infix::Assignment.new(:$lhs, :$rhs) },
        'infix:<==>'   => -> $lhs, $rhs { Q::Infix::Eq.new(:$lhs, :$rhs) },

        'postfix:<()>' => -> $expr, $argumentlist { Q::Postfix::Call.new(:$expr, :$argumentlist) },
        'postfix:<[]>' => -> $expr, $index { Q::Postfix::Index.new(:$expr, :$index) },
        'postfix:<.>'  => -> $expr, $ident { Q::Postfix::Property.new(:$expr, :$ident) },

        my             => -> $ident, $expr = Val::None.new { Q::Statement::My.new(:$ident, :$expr) },
        stexpr         => -> $expr { Q::Statement::Expr.new(:$expr) },
        if             => -> $expr, $block { Q::Statement::If.new(:$expr, :$block) },
        stblock        => -> $block { Q::Statement::Block.new(:$block) },
        sub            => -> $ident, $block { Q::Statement::Sub.new(:$ident, :$block) },
        macro          => -> $ident, $block { Q::Statement::Macro.new(:$ident, :$block) },
        return         => -> $expr = Val::None.new { Q::Statement::Return.new(:$expr) },
        for            => -> $expr, $block { Q::Statement::For.new(:$expr, :$block) },
        while          => -> $expr, $block { Q::Statement::While.new(:$expr, :$block) },
        begin          => -> $block { Q::Statement::BEGIN.new(:$block) },

        ident          => -> $name { Q::Identifier.new(:$name) },
        block          => -> $parameterlist, $statementlist { Q::Block.new(:$parameterlist, :$statementlist) },
        property       => -> $key, $value { Q::Property.new(:$key, :$value) },

        stmtlist       => -> *@statements { Q::StatementList.new(:statements(Val::Array.new(:elements(@statements)))) },
        paramlist      => -> *@parameters { Q::ParameterList.new(:parameters(Val::Array.new(:elements(@parameters)))) },
        arglist        => -> *@arguments { Q::ArgumentList.new(:arguments(Val::Array.new(:elements(@arguments)))) },
        proplist       => -> *@properties { Q::PropertyList.new(:properties(Val::Array.new(:elements(@properties)))) },
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
            make %q_lookup{$qname}(|@rest);
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

role StrOutput {
    has $.result = "";

    method say($s) { $!result ~= $s.gist ~ "\n" }
}

role UnwantedOutput {
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
    multi handle(Q::Term $) {}
    multi handle(Q::Postfix $) {}

    multi handle(Q::StatementList $statementlist) {
        for $statementlist.statements.elements -> $statement {
            handle($statement);
        }
    }

    multi handle(Q::Statement::My $my) {
        my $symbol = $my.ident.name.value;
        my $block = $runtime.current-frame();
        die X::Redeclaration.new(:$symbol)
            if $runtime.declared-locally($symbol);
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$block ~ $symbol};
        $runtime.declare-var($symbol);

        if $my.expr !~~ Val::None {
            handle($my.expr);
        }
    }

    multi handle(Q::Statement::Constant $constant) {
        my $symbol = $constant.ident.name.value;
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
        my $name = $sub.ident.name.value;
        my $val = Val::Sub.new(:$name,
            :parameterlist($sub.block.parameterlist),
            :statementlist($sub.block.statementlist),
            :$outer-frame
        );
        $runtime.enter($val);
        handle($sub.block);
        $runtime.leave();

        $runtime.declare-var($name, $val);
    }

    multi handle(Q::Statement::Macro $macro) {
        my $outer-frame = $runtime.current-frame;
        my $name = $macro.ident.name.value;
        my $val = Val::Macro.new(:$name,
            :parameterlist($macro.block.parameterlist),
            :statementlist($macro.block.statementlist),
            :$outer-frame
        );
        $runtime.enter($val);
        handle($macro.block);
        $runtime.leave();

        $runtime.declare-var($name, $val);
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
            :outer-frame($runtime.current-frame));
        $runtime.enter($valblock);
        handle($block.parameterlist);
        handle($block.statementlist);
        $block.static-lexpad = $runtime.current-frame.pad;
        $runtime.leave();
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
