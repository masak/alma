use v6;
use _007;
use Test;

sub read(Str $ast) is export {
    my %qclass_lookup =
        none        => Q::Literal::None,
        int         => Q::Literal::Int,
        str         => Q::Literal::Str,
        array       => Q::Literal::Array,

        '-'         => Q::Prefix::Minus,

        '+'         => Q::Infix::Addition,
        '~'         => Q::Infix::Concat,
        assign      => Q::Infix::Assignment,
        '=='        => Q::Infix::Eq,

        call        => Q::Postfix::Call,
        index       => Q::Postfix::Index,

        my          => Q::Statement::My,
        stexpr      => Q::Statement::Expr,
        if          => Q::Statement::If,
        stblock     => Q::Statement::Block,
        sub         => Q::Statement::Sub,
        return      => Q::Statement::Return,
        for         => Q::Statement::For,
        while       => Q::Statement::While,
        begin       => Q::Statement::BEGIN,
        macro       => Q::Statement::Macro,

        ident       => Q::Identifier,
        stmtlist    => Q::StatementList,
        paramlist   => Q::ParameterList,
        arglist     => Q::ArgumentList,
        block       => Q::Block,
    ;

    my grammar _007::Syntax {
        regex TOP { \s* <expr> \s* }
        proto token expr {*}
        token expr:list { '(' ~ ')' [<expr>+ % \s+] }
        token expr:int { \d+ }
        token expr:str { '"' ~ '"' ([<-["]> | '\\"']*) }
        token expr:symbol { <!before '"'><!before \d> [<!before ')'> \S]+ }
    }

    my $actions = role {
        method TOP($/) {
            make $<expr>.ast;
        }
        method expr:list ($/) {
            my $qname = ~$<expr>[0];
            die "Unknown name: $qname"
                unless %qclass_lookup{$qname} :exists;
            my $qclass = %qclass_lookup{$qname};
            my @rest = $<expr>».ast[1..*];
            make $qclass.new(|@rest);
        }
        method expr:symbol ($/) { make ~$/ }
        method expr:int ($/) { make +$/ }
        method expr:str ($/) { make ~$0 }
    };

    _007::Syntax.parse($ast, :$actions)
        or die "failure";
    return $/.ast;
}

role Output {
    has $.result = "";

    method say($s) { $!result ~= $s.gist ~ "\n" }
}

role BadOutput {
    method say($s) { die "Program printed '$s'; was not expected to print anything" }
}

sub check($ast, $runtime) {
    my %*assigned;
    handle($ast);
    $ast.static-lexpad = $runtime.current-frame.pad;

    multi handle(Q $ast) {
        # Do nothing for most Q types; exceptions below
    }

    multi handle(Q::StatementList $statementlist) {
        for @$statementlist -> $statement {
            handle($statement);
        }
    }

    multi handle(Q::Statement::My $my) {
        my $symbol = $my.ident.name;
        my $block = $runtime.current-frame();
        die X::Redeclaration.new(:$symbol)
            if $runtime.declared-locally($symbol);
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$block ~ $symbol};
        $runtime.declare-var($symbol);

        if $my.expr {
            handle($my.expr);
        }
    }

    # XXX: should handle Q::Statement::Constant, too

    multi handle(Q::Statement::Block $block) {
        $runtime.enter($block.block.eval($runtime));
        handle($block.block.statementlist);
        $block.block.statementlist.static-lexpad = $runtime.current-frame.pad;
        $runtime.leave();
    }

    multi handle(Q::Statement::Sub $sub) {
        my $outer-frame = $runtime.current-frame;
        my $valblock = Val::Block.new(:$outer-frame);
        $runtime.enter($valblock);
        handle($sub.parameterlist);
        handle($sub.statementlist);
        $sub.statementlist.static-lexpad = $runtime.current-frame.pad;
        $runtime.leave();

        my $name = $sub.ident.name;
        my $valsub = Val::Sub.new(:$name, :parameterlist($sub.parameterlist),
            :statementlist($sub.statementlist), :$outer-frame);
        $runtime.declare-var($name, $valsub);
    }

    multi handle(Q::Statement::Macro $macro) {
        my $outer-frame = $runtime.current-frame;
        my $valblock = Val::Block.new(:$outer-frame);
        $runtime.enter($valblock);
        handle($macro.parameterlist);
        handle($macro.statementlist);
        $macro.statementlist.static-lexpad = $runtime.current-frame.pad;
        $runtime.leave();

        my $name = $macro.ident.name;
        my $valmacro = Val::Macro.new(:$name, :parameterlist($macro.parameterlist),
            :statementlist($macro.statementlist), :$outer-frame);
        $runtime.declare-var($name, $valmacro);
    }

    multi handle(Q::Statement::For $for) {
        handle($for.block);
    }

    multi handle(Q::Block $block) {
        my $valblock = Val::Block.new(
            :outer-frame($runtime.current-frame));
        $runtime.enter($valblock);
        handle($block.parameterlist);
        handle($block.statementlist);
        $block.statementlist.static-lexpad = $runtime.current-frame.pad;
        $runtime.leave();
    }

    multi handle(Q::ParameterList $parameterlist) {
        for @$parameterlist -> $parameter {
            handle($parameter);
        }
    }
}

sub is-result($input, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $ast = read($input);
    my $output = Output.new;
    my $runtime = _007.runtime(:$output);
    check($ast, $runtime);
    $runtime.run($ast);

    is $output.result, $expected, $desc;
}

sub is-error($input, $expected-error, $desc = $expected-error.^name) is export {
    my $ast = read($input);
    my $output = Output.new;
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
    my $output = BadOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $actual-ast = $parser.parse($program);

    empty-diff ~$expected-ast, ~$actual-ast, $desc;
}

sub parse-error($program, $expected-error, $desc = $expected-error.^name) is export {
    my $output = BadOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    $parser.parse($program);

    CATCH {
        when $expected-error {
            pass $desc;
        }
        default {
            is .^name, $expected-error.^name;   # which we know will flunk
            return;
        }
    }
    flunk $desc;
}

sub outputs($program, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $output = Output.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    is $output.result, $expected, $desc;
}
