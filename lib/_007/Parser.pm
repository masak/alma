use _007::Q;

class X::String::Newline is Exception {
    method message { "Found a newline inside a string literal" }
}

class X::PointyBlock::SinkContext is Exception {
    method message { "Pointy blocks cannot occur on the statement level" }
}

class X::Trait::Conflict is Exception {
    has Str $.t1;
    has Str $.t2;

    method message { "Traits '$.t1' and '$.t2' cannot coexist on the same routine" }
}

class X::Op::Nonassociative is Exception {
    has Str $.op1;
    has Str $.op2;

    method message {
        my $name1 = $.op1.type.substr(1, *-1);
        my $name2 = $.op2.type.substr(1, *-1);
        "'$name1' and '$name2' do not associate -- please use parentheses"
    }
}

class X::Trait::IllegalValue is Exception {
    has Str $.trait;
    has Str $.value;

    method message { "The value '$.value' is not compatible with the trait '$.trait'" }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

class X::Precedence::Incompatible is Exception {
    method message { "Trying to relate a pre/postfix operator with an infix operator" }
}

class Prec {
    has $.assoc = "left";
    has %.ops;

    method contains($op) {
        %.ops{$op}:exists;
    }

    method clone {
        self.new(:$.assoc, :%.ops);
    }
}

class OpLevel {
    has %.ops =
        prefix => {},
        infix => {},
        postfix => {},
    ;

    has @.infixprec;
    has @.prepostfixprec;
    has $!prepostfix-boundary = 0;

    method install($type, $op, $q?, :%precedence, :$assoc) {
        %!ops{$type}{$op} = $q !=== Any ?? $q !! {
            prefix => Q::Prefix::Custom[$op],
            infix => Q::Infix::Custom[$op],
            postfix => Q::Postfix::Custom[$op],
        }{$type};

        my @namespace := $type eq 'infix' ?? @!infixprec !! @!prepostfixprec;
        sub new-prec() {
            return Prec.new(:assoc($assoc // "left"), :ops{ $op => $q });
        }
        if %precedence<tighter> || %precedence<looser> -> $other-op {
            my $pos = @namespace.first-index(*.contains($other-op));
            $pos += %precedence<tighter> ?? 1 !! 0;
            @namespace.splice($pos, 0, new-prec());
            if $type eq 'prefix' | 'postfix' && $pos <= $!prepostfix-boundary {
                $!prepostfix-boundary++;
            }
        }
        elsif %precedence<equal> -> $other-op {
            my $prec = @namespace.first(*.contains($other-op));
            die X::Associativity::Conflict.new
                if $assoc !=== Any && $assoc ne $prec.assoc;
            $prec.ops{$op} = $q;
        }
        elsif $type eq 'prefix' {
            @namespace.splice($!prepostfix-boundary++, 0, new-prec());
        }
        else {
            @namespace.push(new-prec());
        }
    }

    method clone {
        my $opl = OpLevel.new(
            infixprec => @.infixprec.map(*.clone),
            prepostfixprec => @.prepostfixprec.map(*.clone),
            :$!prepostfix-boundary,
        );
        for <prefix infix postfix> -> $category {
            for %.ops{$category}.kv -> $op, $q {
                $opl.ops{$category}{$op} = $q;
            }
        }
        return $opl;
    }
}

class Parser {
    has @!oplevels;

    method oplevel { @!oplevels[*-1] }
    method push-oplevel { @!oplevels.push: @!oplevels[*-1].clone }
    method pop-oplevel { @!oplevels.pop }

    submethod BUILD {
        my $opl = OpLevel.new;
        @!oplevels.push: $opl;

        $opl.install('prefix', '-', Q::Prefix::Minus, :assoc<left>);

        $opl.install('infix', '=', Q::Infix::Assignment, :assoc<right>);
        $opl.install('infix', '==', Q::Infix::Eq, :assoc<left>);
        $opl.install('infix', '+', Q::Infix::Addition, :assoc<left>);
        $opl.install('infix', '~', Q::Infix::Concat, :precedence{ equal => "+" });
    }

    grammar Syntax {
        token TOP {
            <.newpad>
            <statements>
            <.finishpad>
        }

        token newpad { <?> {
            $*parser.push-oplevel;
            my $block = Val::Block.new(
                :outer-frame($*runtime.current-frame));
            $*runtime.enter($block)
        } }

        token finishpad { <?> {
            $*parser.pop-oplevel;
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
            <![{]>       # }], you're welcome vim
            <EXPR>
        }
        token statement:block { <pblock> }
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
            <trait> *
            <blockoid>:!s
            <.finishpad>
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
            <.finishpad>
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

        token trait {
            'is' \s* <identifier> '(' <EXPR> ')'
        }

        # requires a <.newpad> before invocation
        # and a <.finishpad> after
        token blockoid {
            '{' ~ '}' <statements>
        }
        token block {
            <?[{]> <.newpad> <blockoid> <.finishpad>    # }], vim
        }

        # "pointy block"
        token pblock {
            | <lambda> <.newpad> <.ws>
                <parameters>
                <blockoid>
                <.finishpad>
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
            my @ops = $*parser.oplevel.ops<prefix>.keys;
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
        token term:quasi { quasi <.ws> '{' ~ '}' <statements> }
        token term:parens { '(' ~ ')' <EXPR> }

        method infix {
            my @ops = $*parser.oplevel.ops<infix>.keys;
            if /@ops/(self) -> $cur {
                return $cur."!reduce"("infix");
            }
            return /<!>/(self);
        }

        method postfix {
            # XXX: should find a way not to special-case [] and ()
            if /$<index>=[ \s* '[' ~ ']' [\s* <EXPR>] ]/(self) -> $cur {
                return $cur."!reduce"("postfix");
            }
            elsif /$<call>=[ \s* '(' ~ ')' [\s* <arguments>] ]/(self) -> $cur {
                return $cur."!reduce"("postfix");
            }

            my @ops = $*parser.oplevel.ops<postfix>.keys;
            if /@ops/(self) -> $cur {
                return $cur."!reduce"("postfix");
            }
            return /<!>/(self);
        }

        token identifier {
            <!before \d> <[\w:]>+ ['<' <-[>]>+ '>']?
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
            die X::PointyBlock::SinkContext.new
                if $<pblock><parameters>;
            make Q::Statement::Block.new($<pblock>.ast);
        }

        sub maybe-install-operator($identname, @trait) {
            return
                unless $identname ~~ / (< prefix infix postfix >)
                                       ':<' (<-[>]>+) '>' /;

            my $type = ~$0;
            my $op = ~$1;

            my %precedence;
            my @prec-traits = <equal looser tighter>;
            my $assoc;
            for @trait -> $trait {
                my $name = $trait<identifier>.ast.name;
                if $name eq any @prec-traits {
                    my $identifier = $trait<EXPR>.ast;
                    my $prep = $name eq "equal" ?? "to" !! "than";
                    die "The thing your op is $name $prep must be an identifier"
                        unless $identifier ~~ Q::Identifier;
                    sub check-if-op($s) {
                        die "Unknown thing in '$name' trait"
                            unless $s ~~ /< pre in post > 'fix:<' (<-[>]>+) '>'/;
                        %precedence{$name} = ~$0;
                        die X::Precedence::Incompatible.new
                            if $type eq ('prefix' | 'postfix') && $s ~~ /^ in/
                            || $type eq 'infix' && $s ~~ /^ < pre post >/;
                    }($identifier.name);
                }
                elsif $name eq "assoc" {
                    my $string = $trait<EXPR>.ast;
                    die "The associativity must be a string"
                        unless $string ~~ Q::Literal::Str;
                    my $value = $string.value;
                    die X::Trait::IllegalValue.new(:trait<assoc>, :$value)
                        unless $value eq any "left", "non", "right";
                    $assoc = $value;
                }
                else {
                    die "Unknown trait '$name'";
                }
            }

            if %precedence.keys > 1 {
                my ($t1, $t2) = %precedence.keys.sort;
                die X::Trait::Conflict.new(:$t1, :$t2)
                    if %precedence{$t1} && %precedence{$t2};
            }

            $*parser.oplevel.install($type, $op, :%precedence, :$assoc);
        }

        method statement:sub ($/) {
            my $identifier = $<identifier>.ast;
            my $subname = ~$<identifier>;

            my $sub = Q::Statement::Sub.new(
                $identifier,
                $<parameters>.ast,
                $<blockoid>.ast);
            $sub.declare($*runtime);
            make $sub;

            maybe-install-operator($identifier.name, @<trait>);
        }

        method statement:macro ($/) {
            my $identifier = $<identifier>.ast;
            my $macroname = ~$<identifier>;

            my $macro = Q::Statement::Macro.new(
                $identifier,
                $<parameters>.ast,
                $<blockoid>.ast);
            $macro.declare($*runtime);
            make $macro;

            maybe-install-operator($identifier.name, @<trait>);
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

        method trait($/) {
            make Q::Trait.new($<identifier>.ast, $<EXPR>.ast);
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
            sub tighter($op1, $op2) {
                my $name1 = $op1.type.substr(1, *-1);
                my $name2 = $op2.type.substr(1, *-1);
                return $*parser.oplevel.infixprec.first-index(*.contains($name1))
                     > $*parser.oplevel.infixprec.first-index(*.contains($name2));
            }

            sub equal($op1, $op2) {
                my $name1 = $op1.type.substr(1, *-1);
                my $name2 = $op2.type.substr(1, *-1);
                return $*parser.oplevel.infixprec.first-index(*.contains($name1))
                    == $*parser.oplevel.infixprec.first-index(*.contains($name2));
            }

            sub left-associative($op) {
                my $name = $op.type.substr(1, *-1);
                return $*parser.oplevel.infixprec.first(*.contains($name)).assoc eq "left";
            }

            sub non-associative($op) {
                my $name = $op.type.substr(1, *-1);
                return $*parser.oplevel.infixprec.first(*.contains($name)).assoc eq "non";
            }

            my @opstack;
            my @termstack = $<termish>[0].ast;
            sub REDUCE {
                my $t2 = @termstack.pop;
                my $op = @opstack.pop;
                my $t1 = @termstack.pop;

                my $name = $op.type.substr(1, *-1);
                my $c = try $*runtime.get-var("infix:<$name>");
                if $c ~~ Val::Macro {
                    @termstack.push($*runtime.call($c, [$t1, $t2]));
                }
                else {
                    @termstack.push($op.new($t1, $t2));

                    if $op === Q::Infix::Assignment {
                        die X::Immutable.new(:method<assignment>, :typename($t1.^name))
                            unless $t1 ~~ Q::Identifier;
                        my $block = $*runtime.current-frame();
                        my $var = $t1.name;
                        %*assigned{$block ~ $var}++;
                    }
                }
            }

            for $<infix>».ast Z $<termish>[1..*]».ast -> ($infix, $term) {
                while @opstack && (tighter(@opstack[*-1], $infix)
                    || equal(@opstack[*-1], $infix) && left-associative($infix)) {
                    REDUCE;
                }
                die X::Op::Nonassociative.new(:op1(@opstack[*-1]), :op2($infix))
                    if @opstack && equal(@opstack[*-1], $infix) && non-associative($infix);
                @opstack.push($infix);
                @termstack.push($term);
            }
            while @opstack {
                REDUCE;
            }

            make @termstack[0];
        }

        method termish($/) {
            sub tighter($op1, $op2) {
                my $name1 = $op1.type.substr(1, *-1);
                my $name2 = $op2.type.substr(1, *-1);
                return $*parser.oplevel.prepostfixprec.first-index(*.contains($name1))
                     > $*parser.oplevel.prepostfixprec.first-index(*.contains($name2));
            }

            sub equal($op1, $op2) {
                my $name1 = $op1.type.substr(1, *-1);
                my $name2 = $op2.type.substr(1, *-1);
                return $*parser.oplevel.prepostfixprec.first-index(*.contains($name1))
                    == $*parser.oplevel.prepostfixprec.first-index(*.contains($name2));
            }

            sub left-associative($op) {
                my $name = $op.type.substr(1, *-1);
                return $*parser.oplevel.prepostfixprec.first(*.contains($name)).assoc eq "left";
            }

            sub non-associative($op) {
                my $name = $op.type.substr(1, *-1);
                return $*parser.oplevel.prepostfixprec.first(*.contains($name)).assoc eq "non";
            }

            make $<term>.ast;

            my @prefixes = @<prefix>.reverse;   # evaluated inside-out
            my @postfixes = @<postfix>;

            sub handle-prefix($/) {
                my $prefix = @prefixes.shift.ast;
                my $name = $prefix.type.substr(1, *-1);
                my $c = try $*runtime.get-var("prefix:<$name>");
                if $c ~~ Val::Macro {
                    make $*runtime.call($c, [$/.ast]);
                }
                else {
                    make $prefix.new($/.ast);
                }
            }

            sub handle-postfix($/) {
                my $postfix = @postfixes.shift.ast;
                # XXX: factor the logic that checks for macro call out into its own helper sub
                my @p = $postfix.list;
                if @p[0] ~~ Q::Postfix::Call
                && $/.ast ~~ Q::Identifier
                && (my $macro = $*runtime.get-var($/.ast.name)) ~~ Val::Macro {
                    my @args = @p[1].arguments;
                    my $qtree = $*runtime.call($macro, @args);
                    make $qtree;
                }
                elsif @p >= 2 {
                    make @p[0].new($/.ast, @p[1]);
                }
                else {
                    my $name = $postfix.type.substr(1, *-1);
                    my $c = try $*runtime.get-var("postfix:<$name>");
                    if $c ~~ Val::Macro {
                        make $*runtime.call($c, [$/.ast]);
                    }
                    else {
                        make $postfix.new($/.ast);
                    }
                }
            }

            while @postfixes || @prefixes {
                if @postfixes && !@prefixes {
                    handle-postfix($/);
                }
                elsif @prefixes && !@postfixes {
                    handle-prefix($/);
                }
                else {
                    my $prefix = @prefixes[0].ast;
                    my $postfix = @postfixes[0].ast;
                    die X::Op::Nonassociative.new(:op1($prefix), :op2($postfix))
                        if equal($prefix, $postfix) && non-associative($prefix);
                    if tighter($prefix, $postfix)
                        || equal($prefix, $postfix) && left-associative($prefix) {

                        handle-prefix($/);
                    }
                    else {
                        handle-postfix($/);
                    }
                }
            }
        }

        method prefix($/) {
            make $*parser.oplevel.ops<prefix>{~$/};
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

        method term:parens ($/) {
            make $<EXPR>.ast;
        }

        method infix($/) {
            make $*parser.oplevel.ops<infix>{~$/};
        }

        method postfix($/) {
            # XXX: this can't stay hardcoded forever, but we don't have the machinery yet
            # to do these right enough
            if $<index> {
                make [Q::Postfix::Index, $<EXPR>.ast];
            }
            elsif $<call> {
                make [Q::Postfix::Call, $<arguments>.ast];
            }
            else {
                make $*parser.oplevel.ops<postfix>{~$/};
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
        my $*parser = self;
        Syntax.parse($program, :actions(Actions))
            or die "Could not parse program";   # XXX: make this into X::
        return $/.ast;
    }
}
