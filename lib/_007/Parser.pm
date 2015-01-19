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

add-prefix('-', Q::Prefix::Minus);

add-infix('=', Q::Infix::Assignment);
add-infix('==', Q::Infix::Eq);
add-infix('+', Q::Infix::Addition);
add-infix('~', Q::Infix::Concat);     # XXX: should really have the same prec as +

class Parser {
    grammar Syntax {
        token TOP {
            <.newpad>
            <statements>
        }

        token newpad { <?> {
            my $block = Val::Block.new(
                :outer-frame($*runtime.current-frame));
            $*runtime.enter($block)
        } }

        rule statements {
            '' [<statement><.eat_terminator> ]*
        }

        method panic($what) {
            die X::Syntax::Missing.new(:$what);
        }

        proto token statement {*}
        rule statement:my {
            my [<identifier> || <.panic("identifier")>]
            {
                my $symbol = $<identifier>.Str;
                my $block = $*runtime.current-frame();
                die X::Redeclaration.new(:$symbol)
                    if $*runtime.declared-locally($symbol);
                die X::Redeclaration::Outer.new(:$symbol)
                    if %*assigned{$block ~ $symbol};
                $*runtime.declare-var($symbol);
            }
            ['=' <EXPR>]?
        }
        rule statement:constant {
            constant <identifier>
            {
                my $var = $<identifier>.Str;
                $*runtime.declare-var($var);
            }
            ['=' <EXPR>]?     # XXX: X::Syntax::Missing if this doesn't happen
                                # 'Missing initializer on constant declaration'
        }
        token statement:expr {
            <![{]>       # prevent mixup with statement:block
            <EXPR>
        }
        token statement:block { <block> }
        rule statement:sub {
            sub [<identifier> || <.panic("identifier")>]
            :my $*insub = True;
            {
                my $symbol = $<identifier>.Str;
                my $block = $*runtime.current-frame();
                die X::Redeclaration::Outer.new(:$symbol)
                    if %*assigned{$block ~ $symbol};
                $*runtime.declare-var($symbol);
            }
            <.newpad>
            '(' ~ ')' <parameters>
            <blockoid>:!s
        }
        rule statement:macro {
            macro <identifier>
            :my $*insub = True;
            {
                my $symbol = $<identifier>.Str;
                my $block = $*runtime.current-frame();
                die X::Redeclaration::Outer.new(:$symbol)
                    if %*assigned{$block ~ $symbol};
                $*runtime.declare-var($symbol);
            }
            <.newpad>
            '(' ~ ')' <parameters>
            <blockoid>:!s
        }
        token statement:return {
            return [\s+ <EXPR>]?
            {
                die X::ControlFlow::Return.new
                    unless $*insub;
            }
        }
        token statement:if {
            if \s+ <xblock>
        }
        token statement:for {
            for \s+ <xblock>
        }
        token statement:while {
            while \s+ <xblock>
        }
        token statement:BEGIN {
            BEGIN <.ws> <block>
        }

        # requires a <.newpad> before invocation
        token blockoid {
            '{' ~ '}' <statements>
        }
        token block {
            <?[{]> <.newpad> <blockoid>
        }

        # "pointy block"
        token pblock {
            | <lambda> <.newpad> <.ws>
                <parameters>
                <blockoid>
            | <block>
        }
        token lambda { '->' }

        # "eXpr block"
        token xblock {
            <EXPR> <pblock>
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
        token term:str { '"' ([<-["]> | '\\"']*) '"' }
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
        token term:block { <pblock> }
        token term:quasi { quasi <.ws> '{' ~ '}' <statements> }

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
            <!before \d> <[\w:]>+
        }

        rule arguments {
            <EXPR> *% ','
        }

        rule parameters {
            [<identifier>
                {
                    my $symbol = $<identifier>[*-1].Str;
                    die X::Redeclaration.new(:$symbol)
                        if $*runtime.declared-locally($symbol);
                    $*runtime.declare-var($symbol);
                }
            ]* % ','
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
                    Q::Infix::Assignment.new(
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
                    Q::Infix::Assignment.new(
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
            if $<EXPR>.ast ~~ Q::Statement::Block {
                my @statements = $<EXPR>.ast.block.statements.statements.list;
                die "Can't handle this case with more than one statement yet" # XXX
                    if @statements > 1;
                make @statements[0];
            }
            else {
                make Q::Statement::Expr.new($<EXPR>.ast);
            }
        }

        method statement:block ($/) {
            make Q::Statement::Block.new($<block>.ast);
        }

        method statement:sub ($/) {
            make Q::Statement::Sub.new(
                $<identifier>.ast,
                $<parameters>.ast,
                $<blockoid>.ast);
        }

        method statement:macro ($/) {
            my $macro = Q::Statement::Macro.new(
                $<identifier>.ast,
                $<parameters>.ast,
                $<blockoid>.ast);
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
            make Q::Statement::If.new(|$<xblock>.ast);
        }

        method statement:for ($/) {
            make Q::Statement::For.new(|$<xblock>.ast);
        }

        method statement:while ($/) {
            make Q::Statement::While.new(|$<xblock>.ast);
        }

        method statement:BEGIN ($/) {
            my $bl = $<block>.ast;
            make Q::Statement::BEGIN.new($bl);
            $*runtime.run($bl.statements);
        }

        sub tighter-or-equal($op1, $op2) {
            return @infixprec.first-index($op1) >= @infixprec.first-index($op2);
        }

        method blockoid ($/) {
            my $st = $<statements>.ast;
            make $st;
            self.finish-block($st);
        }
        method block ($/) {
            make Q::Literal::Block.new(
                Q::Parameters.new,
                $<blockoid>.ast);
        }
        method pblock ($/) {
            if $<parameters> {
                make Q::Literal::Block.new(
                    $<parameters>.ast,
                    $<blockoid>.ast);
            } else {
                make $<block>.ast;
            }
        }
        method xblock ($/) {
            make ($<EXPR>.ast, $<pblock>.ast);
        }

        method EXPR($/) {
            my @opstack;
            my @termstack = $<termish>[0].ast;
            sub REDUCE {
                my $t2 = @termstack.pop;
                my $op = @opstack.pop;
                my $t1 = @termstack.pop;
                @termstack.push($op.new($t1, $t2));

                if $op === Q::Infix::Assignment {
                    die X::Immutable.new(:method<assignment>, :typename($t1.^name))
                        unless $t1 ~~ Q::Identifier;
                    my $block = $*runtime.current-frame();
                    my $var = $t1.name;
                    %*assigned{$block ~ $var}++;
                }
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
                # XXX: factor the logic that checks for macro call out into its own helper sub
                my @p = $postfix.ast.list;
                if @p[0] ~~ Q::Postfix::Call
                && $/.ast ~~ Q::Identifier
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
            make $<pblock>.ast;
        }

        method term:quasi ($/) {
            make Q::Quasi.new($<statements>.ast);
        }

        method infix($/) {
            make %ops<infix>{~$/};
        }

        method postfix($/) {
            # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
            # to do these right enough
            if $<index> {
                make [Q::Postfix::Index, $<EXPR>.ast];
            }
            else {
                make [Q::Postfix::Call, $<arguments>.ast];
            }
        }

        method identifier($/) {
            make Q::Identifier.new(~$/);
        }

        method arguments($/) {
            make Q::Arguments.new($<EXPR>».ast);
        }

        method parameters($/) {
            make Q::Parameters.new($<identifier>».ast);
        }
    }

    method parse($program, :$*runtime = die "Must supply a runtime") {
        my %*assigned;
        my $*insub = False;
        Syntax.parse($program, :actions(Actions))
            or die "Could not parse program";   # XXX: make this into X::
        return $/.ast;
    }
}
