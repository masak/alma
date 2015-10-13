use _007::Val;

grammar _007::Parser::Syntax {
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
        <trait> *
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

    token termish { <prefix>* [<term>|<term=unquote>] <postfix>* }

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
    token term:none { None >> }
    token term:int { \d+ }
    token term:str { '"' ([<-["]> | '\\"']*) '"' }
    token term:array { '[' ~ ']' <EXPR>* % [\h* ',' \h*] }
    token term:parens { '(' ~ ')' <EXPR> }
    token term:identifier {
        <identifier>
        {
            my $symbol = $<identifier>.Str;
            $*runtime.get-var($symbol);     # will throw an exception if it isn't there
            die X::Undeclared.new(:$symbol)
                unless $*runtime.declared($symbol);
        }
    }
    token term:quasi { quasi >> [<.ws> '{' ~ '}' <statements> || <.panic("quasi")>] }

    token unquote { '{{{' <EXPR> '}}}' }

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
        <!before \d> [\w+]+ % '::'
            [ <?after \w> [':<' <-[>]>+ '>']?  || <.panic("identifier")> ]
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
