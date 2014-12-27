use _007::Q;

class X::String::Newline is Exception {
}

class X::PointyBlock::SinkContext is Exception {
}

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
            <.newpad>
            <statements>
        }

        token newpad { <?> {
            my $block = Val::Block.new(
                :outer-frame($*runtime.current-frame));
            $*runtime.enter($block)
        } }

        regex statements {
            [<statement> <.eat_terminator> \s*]*
        }

        proto token statement {*}
        token statement:my {
            'my ' <identifier>
            {
                my $symbol = $<identifier>.Str;
                die X::Redeclaration.new(:$symbol)
                    if $*runtime.declared-locally($symbol);
                $*runtime.declare-var($symbol);
            }
            [' = ' <EXPR>]?
        }
        token statement:constant {
            'constant ' <identifier>
            {
                my $var = $<identifier>.Str;
                $*runtime.declare-var($var);
            }
            [' = ' <EXPR>]?     # XXX: X::Syntax::Missing if this doesn't happen
                                # 'Missing initializer on constant declaration'
        }
        token statement:expr {
            <!before \s* '{'>       # prevent mixup with statement:block
            <EXPR>
        }
        token statement:block {
            '{' ~ '}' [
             <.newpad>
             \s* <statements>]
        }
        token statement:sub {
            'sub' \s+
            <identifier>
            {
                my $var = $<identifier>.Str;
                $*runtime.declare-var($var);
            }
            <.newpad>
            '(' ~ ')' <parameters> \s*
            '{' ~ '}' [\s* <statements>]
        }
        token statement:macro {
            'macro' \s+
            <identifier>
            {
                my $var = $<identifier>.Str;
                $*runtime.declare-var($var);
            }
            <.newpad>
            '(' ~ ')' <parameters> \s*
            '{' ~ '}' [\s* <statements>]
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
        }
        token statement:for {
            'for' \s+
            <EXPR> \s*
            <.newpad>
            ['->' \s* <parameters>]? \s*
            '{' ~ '}' [\s* <statements>]
        }
        token statement:while {
            'while' \s+
            <EXPR> \s*
            <.newpad>
            '{' ~ '}' [\s* <statements>]
        }
        token statement:BEGIN {
            'BEGIN' \s*
            '{' ~ '}' [
             <.newpad>
             \s* <statements>]
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
                $*runtime.get-var($symbol);     # will throw an exception if it isn't there
                die X::Undeclared.new(:$symbol)
                    unless $*runtime.declared($symbol);
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
            <[\w:]>+
        }

        token arguments {
            <EXPR>* % [\s* ',' \s*]
        }

        token parameters {
            [<identifier>
                {
                    my $symbol = $<identifier>[*-1].Str;
                    die X::Redeclaration.new(:$symbol)
                        if $*runtime.declared-locally($symbol);
                    $*runtime.declare-var($symbol);
                }
            ]* % [\s* ',' \s*]
        }
    }

    class Actions {
        method finish-block($st) {
            $st.static-lexpad = $*runtime.current-frame.pad;
            $*runtime.leave;
        }

        method TOP($/) {
            my $st = $<statements>.ast;
            make $st;
            self.finish-block($st);
        }

        method statements($/) {
            make Q::Statements.new($<statement>».ast);
        }

        method statement:my ($/) {
            if $<EXPR> {
                make Q::Statement::My.new(
                    $<identifier>.ast,
                    Q::Expr::Infix::Assignment.new(
                        $<identifier>.ast,
                        $<EXPR>.ast));
            }
            else {
                make Q::Statement::My.new($<identifier>.ast);
            }
        }

        method statement:constant ($/) {
            if $<EXPR> {
                make Q::Statement::Constant.new(
                    $<identifier>.ast,
                    Q::Expr::Infix::Assignment.new(
                        $<identifier>.ast,
                        $<EXPR>.ast));
            }
            else {  # XXX: remove this part once we throw an error
                make Q::Statement::Constant.new($<identifier>.ast);
            }
            my $name = $<identifier>.ast.name;
            my $value = $<EXPR>.ast.eval($*runtime);
            $*runtime.put-var($name, $value);
        }

        method statement:expr ($/) {
            die X::PointyBlock::SinkContext.new
                if $<EXPR>.ast ~~ Q::Literal::Block;
            make Q::Statement::Expr.new($<EXPR>.ast);
        }

        method statement:block ($/) {
            my $st = $<statements>.ast;
            make Q::Statement::Block.new(
                Q::Literal::Block.new(
                    Q::Parameters.new,
                    $st));
            self.finish-block($st);
        }

        method statement:sub ($/) {
            my $st = $<statements>.ast;
            make Q::Statement::Sub.new(
                $<identifier>.ast,
                $<parameters>.ast,
                $st);
            self.finish-block($st);
        }

        method statement:macro ($/) {
            my $st = $<statements>.ast;
            my $macro = Q::Statement::Macro.new(
                $<identifier>.ast,
                $<parameters>.ast,
                $st);
            self.finish-block($st);
            $macro.declare($*runtime);
            make $macro;
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
            my $st = $<statements>.ast;
            make Q::Statement::If.new(
                $<EXPR>.ast,
                Q::Literal::Block.new(
                    Q::Parameters.new,  # XXX: generalize this (allow '->' syntax)
                    $st));
            self.finish-block($st);
        }

        method statement:for ($/) {
            my $parameters = ($<parameters> ?? $<parameters>.ast !! Q::Parameters.new);
            my $st = $<statements>.ast;
            make Q::Statement::For.new(
                $<EXPR>.ast,
                Q::Literal::Block.new(
                    $parameters,
                    $st));
            self.finish-block($st);
        }

        method statement:while ($/) {
            my $st = $<statements>.ast;
            make Q::Statement::While.new(
                $<EXPR>.ast,
                Q::Literal::Block.new(
                    Q::Parameters.new,  # XXX: generalize this (allow '->' syntax)
                    $st));
            self.finish-block($st);
        }

        method statement:BEGIN ($/) {
            my $st = $<statements>.ast;
            make Q::Statement::BEGIN.new(
                Q::Literal::Block.new(
                    Q::Parameters.new,
                    $st));
            self.finish-block($st);
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
                if @p[0] ~~ Q::Expr::Call::Sub
                && $/.ast ~~ Q::Term::Identifier
                && (my $macro = $*runtime.get-var($/.ast.name)) ~~ Val::Macro {
                    my @args = @p[1].arguments;
                    my $qtree = $*runtime.call($macro, @args);
                    make $qtree;
                }
                else {
                    make @p[0].new($/.ast, @p[1]);
                }
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
                make [Q::Expr::Postfix::Index, $<EXPR>.ast];
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
