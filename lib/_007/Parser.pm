use _007::Q;

class X::String::Newline is Exception {
}

class X::PointyBlock::SinkContext is Exception {
}

class Lexpad {
    has %!variables;

    method add_variable($var) {
        %!variables{$var}++;
    }

    method knows($var) {
        %!variables{$var} :exists;
    }
}

sub add_variable($var) { @*PADS[*-1].add_variable($var) }

my %ops =
    prefix => {},
    infix => {},
;
my @infixprec;
my @prepostfixprec;

sub add-prefix($op, $q) {
    %ops<prefix>{$op} = $q;
    @prepostfixprec.push($q);
}

sub add-infix($op, $q) {
    %ops<infix>{$op} = $q;
    @infixprec.push($q);
}

add-prefix('-', Q::Expr::Prefix::Minus);

add-infix('=', Q::Expr::Infix::Assignment);
add-infix('==', Q::Expr::Infix::Eq);
add-infix('+', Q::Expr::Infix::Addition);
add-infix('~', Q::Expr::Infix::Concat);     # XXX: should really have the same prec as +

class Parser {
    grammar Syntax {
        regex TOP {
            :my @*PADS;
            <.newpad>
            <statements>
        }

        token newpad { <?> { @*PADS.push(Lexpad.new) } }
        token finishpad { <?> { @*PADS.pop } }

        regex statements {
            [<statement> <.eat_terminator> \s*]*
        }

        proto token statement {*}
        token statement:vardecl {
            'my ' <identifier>
            {
                my $var = $<identifier>.Str;
                add_variable($var);
            }
            [' = ' <EXPR>]?
        }
        token statement:expr {
            <!before \s* '{'>       # prevent mixup with statement:block
            <EXPR>
        }
        token statement:block {
            '{' ~ '}' [
             <.newpad>
             \s* <statements>]
             <.finishpad>
        }
        token statement:sub {
            'sub' \s+
            <identifier>
            {
                my $var = $<identifier>.Str;
                add_variable($var);
            }
            <.newpad>
            '(' ~ ')' <parameters> \s*
            '{' ~ '}' [\s* <statements>]
            <.finishpad>
        }
        token statement:return {
            'return'
            [\s+ <EXPR>]?
            \s*
        }
        token statement:if {
            'if' \s+
            <EXPR> \s*
            <.newpad>
            '{' ~ '}' [\s* <statements>]
            <.finishpad>
        }
        token statement:for {
            'for' \s+
            <EXPR> \s*
            <.newpad>
            ['->' \s* <parameters>]? \s*
            '{' ~ '}' [\s* <statements>]
            <.finishpad>
        }
        token statement:while {
            'while' \s+
            <EXPR> \s*
            <.newpad>
            '{' ~ '}' [\s* <statements>]
            <.finishpad>
        }
        token statement:BEGIN {
            'BEGIN' \s*
            '{' ~ '}' [
             <.newpad>
             \s* <statements>]
             <.finishpad>
        }

        token eat_terminator {
            || \s* ';'
            || <?after '}'> $$
            || \s* <?before '}'>
            || \s* $
        }

        rule EXPR { <termish> +% <infix> }

        token termish { <prefix>* <term> <postfix>* }

        method prefix {
            # XXX: remove this hack
            if / '->' /(self) {
                return /<!>/(self);
            }
            my @ops = %ops<prefix>.keys;
            if /@ops/(self) -> $cur {
                return $cur."!reduce"("prefix");
            }
            return /<!>/(self);
        }

        proto token term {*}
        token term:int { \d+ }
        token term:str { '"' (<-["]>*) '"' }
        token term:array { '[' ~ ']' <EXPR>* % [\h* ',' \h*] }
        token term:identifier {
            <identifier>
            {
                my $symbol = $<identifier>.Str;
                die X::Undeclared.new(:$symbol)
                    unless any(@*PADS).knows($symbol)
                     || $symbol eq 'say';   # XXX: remove this exception
            }
        }
        token term:block { ['->' \s* <parameters>]? \s* '{' ~ '}' [\s* <statements> ] }

        method infix {
            my @ops = %ops<infix>.keys;
            if /@ops/(self) -> $cur {
                return $cur."!reduce"("infix");
            }
            return /<!>/(self);
        }

        token postfix {
            | $<index>=[ \s* '[' ~ ']' [\s* <EXPR>] ]
            | $<call>=[ \s* '(' ~ ')' [\s* <arguments>] ]
        }

        token identifier {
            \w+
        }

        token arguments {
            <EXPR>* % [\s* ',' \s*]
        }

        token parameters {
            [<identifier>
                {
                    my $symbol = $<identifier>[*-1].Str;
                    die X::Redeclaration.new(:$symbol)
                        if @*PADS[*-1].knows($symbol);
                    add_variable($symbol);
                }
            ]* % [\s* ',' \s*]
        }
    }

    class Actions {
        method TOP($/) {
            make $<statements>.ast;
        }

        method statements($/) {
            make Q::Statements.new($<statement>».ast);
        }

        method statement:vardecl ($/) {
            if $<EXPR> {
                make Q::Statement::VarDecl.new(
                    $<identifier>.ast,
                    Q::Expr::Infix::Assignment.new(
                        $<identifier>.ast,
                        $<EXPR>.ast));
            }
            else {
                make Q::Statement::VarDecl.new($<identifier>.ast);
            }
        }

        method statement:expr ($/) {
            die X::PointyBlock::SinkContext.new
                if $<EXPR>.ast ~~ Q::Literal::Block;
            make Q::Statement::Expr.new($<EXPR>.ast);
        }

        method statement:block ($/) {
            make Q::Statement::Block.new(
                Q::Literal::Block.new(
                    Q::Parameters.new,
                    $<statements>.ast));
        }

        method statement:sub ($/) {
            make Q::Statement::Sub.new(
                $<identifier>.ast,
                $<parameters>.ast,
                $<statements>.ast);
        }

        method statement:return ($/) {
            if $<EXPR> {
                make Q::Statement::Return.new(
                    $<EXPR>.ast);
            }
            else {
                make Q::Statement::Return.new;
            }
        }

        method statement:if ($/) {
            make Q::Statement::If.new(
                $<EXPR>.ast,
                Q::Literal::Block.new(
                    Q::Parameters.new,  # XXX: generalize this (allow '->' syntax)
                    $<statements>.ast));
        }

        method statement:for ($/) {
            my $parameters = ($<parameters> ?? $<parameters>.ast !! Q::Parameters.new);
            make Q::Statement::For.new(
                $<EXPR>.ast,
                Q::Literal::Block.new(
                    $parameters,
                    $<statements>.ast));
        }

        method statement:while ($/) {
            make Q::Statement::While.new(
                $<EXPR>.ast,
                Q::Literal::Block.new(
                    Q::Parameters.new,  # XXX: generalize this (allow '->' syntax)
                    $<statements>.ast));
        }

        method statement:BEGIN ($/) {
            make Q::Statement::BEGIN.new(
                Q::Literal::Block.new(
                    Q::Parameters.new,
                    $<statements>.ast));
            $*runtime.run($<statements>.ast);
        }

        sub tighter-or-equal($op1, $op2) {
            return @infixprec.first-index($op1) >= @infixprec.first-index($op2);
        }

        method EXPR($/) {
            my @opstack;
            my @termstack = $<termish>[0].ast;
            sub REDUCE {
                my $t2 = @termstack.pop;
                my $op = @opstack.pop;
                my $t1 = @termstack.pop;
                @termstack.push($op.new($t1, $t2));
            }

            for $<infix>».ast Z $<termish>[1..*]».ast -> $infix, $term {
                while @opstack && tighter-or-equal(@opstack[*-1], $infix) {
                    REDUCE;
                }
                @opstack.push($infix);
                @termstack.push($term);
            }
            while @opstack {
                REDUCE;
            }

            make @termstack[0];
        }

        method termish($/) {
            make $<term>.ast;
            # XXX: need to think more about precedence here
            for $<postfix>.list -> $postfix {
                my @p = $postfix.ast.list;
                make @p[0].new($/.ast, @p[1]);
            }
            for $<prefix>.list -> $prefix {
                make $prefix.ast.new($/.ast);
            }
        }

        method prefix($/) {
            make %ops<prefix>{~$/};
        }

        method term:int ($/) {
            make Q::Literal::Int.new(+$/);
        }

        method term:str ($/) {
            sub check-for-newlines($s) {
                die X::String::Newline.new
                    if $s ~~ /\n/;
            }(~$0);
            make Q::Literal::Str.new(~$0);
        }

        method term:array ($/) {
            make Q::Literal::Array.new($<EXPR>».ast);
        }

        method term:identifier ($/) {
            make $<identifier>.ast;
        }

        method term:block ($/) {
            my $parameters = ($<parameters> ?? $<parameters>.ast !! Q::Parameters.new);
            make Q::Literal::Block.new(
                $parameters,
                $<statements>.ast);
        }

        method infix($/) {
            make %ops<infix>{~$/};
        }

        method postfix($/) {
            # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
            # to do these right enough
            if $<index> {
                make [Q::Expr::Index, $<EXPR>.ast];
            }
            else {
                make [Q::Expr::Call::Sub, $<arguments>.ast];
            }
        }

        method identifier($/) {
            make Q::Term::Identifier.new(~$/);
        }

        method arguments($/) {
            make Q::Arguments.new($<EXPR>».ast);
        }

        method parameters($/) {
            make Q::Parameters.new($<identifier>».ast);
        }
    }

    method parse($program, :$*runtime = die "Must supply a runtime") {
        Syntax.parse($program, :actions(Actions))
            or die "Could not parse program";   # XXX: make this into X::
        return $/.ast;
    }
}
