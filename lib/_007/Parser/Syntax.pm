use _007::Val;
use _007::Q;
use _007::Parser::Exceptions;

grammar _007::Parser::Syntax {
    token TOP {
        <.newpad>
        <statementlist>
        <.finishpad>
    }

    token newpad { <?> {
        $*parser.push-oplevel;
        @*declstack.push(@*declstack ?? @*declstack[*-1].clone !! {});
        my $block = Val::Block.new(
            :parameterlist(Q::ParameterList.new),
            :statementlist(Q::StatementList.new),
            :outer-frame($*runtime.current-frame));
        $*runtime.enter($block)
    } }

    token finishpad { <?> {
        @*declstack.pop;
        $*parser.pop-oplevel;
    } }

    rule statementlist {
        '' [<statement><.eat_terminator> ]*
    }

    method panic($what) {
        die X::Syntax::Missing.new(:$what);
    }

    sub declare(Q::Declaration $decltype, $symbol) {
        die X::Redeclaration.new(:$symbol)
            if $*runtime.declared-locally($symbol);
        my $block = $*runtime.current-frame();
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$block ~ $symbol};
        $*runtime.declare-var($symbol);
        @*declstack[*-1]{$symbol} = $decltype;
    }

    proto token statement {*}
    rule statement:my {
        my [<identifier> || <.panic("identifier")>]
        { declare(Q::Statement::My, $<identifier>.Str); }
        ['=' <EXPR>]?
    }
    rule statement:constant {
        constant <identifier>
        {
            my $symbol = $<identifier>.Str;
            # XXX: a suspicious lack of redeclaration checks here
            declare(Q::Statement::Constant, $symbol);
        }
        ['=' <EXPR>]?
    }
    token statement:expr {
        <![{]>       # }], you're welcome vim
        <EXPR>
    }
    token statement:block { <pblock> }
    rule statement:sub {
        sub [<identifier> || <.panic("identifier")>]
        :my $*insub = True;
        { declare(Q::Statement::Sub, $<identifier>.Str); }
        <.newpad>
        '(' ~ ')' <parameterlist>
        <trait> *
        <blockoid>:!s
        <.finishpad>
    }
    rule statement:macro {
        macro [<identifier> || <.panic("identifier")>]
        :my $*insub = True;
        { declare(Q::Statement::Macro, $<identifier>.Str); }
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
    token term:none { None >> <!before <.ws> '{'> }
    token term:int { \d+ }
    token term:array { '[' ~ ']' [<.ws> <EXPR>]* %% [\h* ','] }
    token term:str { <str> }
    token term:parens { '(' ~ ')' <EXPR> }
    token term:quasi { quasi <.ws>
        [
            || "@" <.ws> "Q::Infix" <.ws> '{' <.ws> <infix> <.ws> '}'
            || "@" <.ws> "Q::Prefix" <.ws> '{' <.ws> <prefix> <.ws> '}'
            || <block>
            || <.panic("quasi")>
        ]
    }
    token term:object {
        [<identifier> <?{ $*runtime.maybe-get-var(~$<identifier>) ~~ Val::Type }> <.ws>]?
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
        [<parameter>
        { declare(Q::Parameter, $<parameter>[*-1]<identifier>.Str); }
        ]* % ','
    }

    rule parameter {
        <identifier>
    }
}
