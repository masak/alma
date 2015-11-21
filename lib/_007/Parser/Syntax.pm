use _007::Val;
use _007::Parser::Exceptions;

grammar _007::Parser::Syntax {
    token TOP {
        <.newpad>
        <statementlist>
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

    rule statementlist {
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
        '(' ~ ')' <parameterlist>
        <trait> *
        <blockoid>:!s
        <.finishpad>
    }
    rule statement:macro {
        macro [<identifier> || <.panic("identifier")>]
        :my $*insub = True;
        {
            my $symbol = $<identifier>.Str;
            my $block = $*runtime.current-frame();
            die X::Redeclaration::Outer.new(:$symbol)
                if %*assigned{$block ~ $symbol};
            $*runtime.declare-var($symbol);
        }
        <.newpad>
        '(' ~ ')' <parameterlist>
        <trait> *
        <blockoid>:!s
        <.finishpad>
    }
    token statement:return {
        return [<.ws> <EXPR>]?
        {
            die X::ControlFlow::Return.new
                unless $*insub;
        }
    }
    token statement:if {
        if <.ws> <xblock>
    }
    token statement:for {
        for <.ws> <xblock>
    }
    token statement:while {
        while <.ws> <xblock>
    }
    token statement:BEGIN {
        BEGIN <.ws> <block>
    }

    token trait {
        'is' <.ws> <identifier> '(' <EXPR> ')'
    }

    # requires a <.newpad> before invocation
    # and a <.finishpad> after
    token blockoid {
        '{' ~ '}' <statementlist>
    }
    token block {
        <?[{]> <.newpad> <blockoid> <.finishpad>    # }], vim
    }

    # "pointy block"
    token pblock {
        | <lambda> <.newpad> <.ws>
            <parameterlist>
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
        || <.ws> ';'
        || <?after '}'> $$
        || <.ws> <?before '}'>
        || <.ws> $
    }

    rule EXPR { <termish> +% <infix> }

    token termish { <prefix>* [<term>|<term=unquote>] <postfix>* }

    method prefix {
        my @ops = $*parser.oplevel.ops<prefix>.keys;
        if /@ops/(self) -> $cur {
            return $cur."!reduce"("prefix");
        }
        return /<!>/(self);
    }

    token str { '"' ([<-["]> | '\\\\' | '\\"']*) '"' }

    proto token term {*}
    token term:none { None >> }
    token term:int { \d+ }
    token term:array { '[' ~ ']' [<.ws> <EXPR>]* %% [\h* ','] }
    token term:str { <str> }
    token term:parens { '(' ~ ')' <EXPR> }
    token term:quasi { quasi >> [<.ws> <block> || <.panic("quasi")>] }
    token term:object {
        [<identifier> <?{ $*parser.types{$<identifier>} }> <.ws>]?
        '{' ~ '}' <propertylist>
    }
    token term:identifier {
        <identifier>
        {
            my $name = $<identifier>.Str;
            if !$*runtime.declared($name) {
                my $frame = $*runtime.current-frame;
                $*parser.postpone: sub checking-postdeclared {
                    my $value = $*runtime.get-var($name, $frame);
                    die X::Macro::Postdeclared.new(:$name)
                        if $value ~~ Val::Macro;
                    die X::Undeclared.new(:symbol($name))
                        unless $value ~~ Val::Sub;
                };
            }
        }
    }

    token propertylist { [<.ws> <property>]* % [\h* ','] <.ws> }

    token unquote { '{{{' <EXPR> '}}}' }

    proto token property {*}
    rule property:str-expr { <key=str> ':' <value=term> }
    rule property:ident-expr { <identifier> ':' <value=term> }
    rule property:method {
        <identifier>
        <.newpad>
        '(' ~ ')' <parameterlist>
        <trait> *
        <blockoid>:!s
        <.finishpad>
    }
    token property:ident { <identifier> }

    method infix {
        my @ops = $*parser.oplevel.ops<infix>.keys;
        if /@ops/(self) -> $cur {
            return $cur."!reduce"("infix");
        }
        return /<!>/(self);
    }

    method postfix {
        # XXX: should find a way not to special-case [] and () and .
        if /$<index>=[ <.ws> '[' ~ ']' [<.ws> <EXPR>] ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        elsif /$<call>=[ <.ws> '(' ~ ')' [<.ws> <argumentlist>] ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        elsif /$<prop>=[ <.ws> '.' <identifier> ]/(self) -> $cur {
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

    rule argumentlist {
        <EXPR> *% ','
    }

    rule parameterlist {
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
