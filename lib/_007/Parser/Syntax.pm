use _007::Val;
use _007::Q;

sub check-feature-flag($feature, $word) {
    my $flag = "FLAG_007_{$word}";
    die "{$feature} is experimental and requires \%*ENV<{$flag}> to be set"
        unless %*ENV{$flag};
}

grammar _007::Parser::Syntax {
    token TOP { <compunit> }

    token compunit {
        <.newpad>
        <statementlist>
        <.finishpad>
    }

    token newpad { <?> {
        $*parser.push-opscope;
        @*declstack.push(@*declstack ?? @*declstack[*-1].clone !! {});
        my $block = Val::Block.new(
            :parameterlist(Q::ParameterList.new),
            :statementlist(Q::StatementList.new),
            :outer-frame($*runtime.current-frame));
        $*runtime.enter($block)
    } }

    token finishpad { <?> {
        @*declstack.pop;
        $*parser.pop-opscope;
    } }

    rule statementlist {
        '' [<statement><.eat_terminator> ]*
    }

    method panic($what) {
        die X::Syntax::Missing.new(:$what);
    }

    our sub declare(Q::Declaration $decltype, $symbol) {
        die X::Redeclaration.new(:$symbol)
            if $*runtime.declared-locally($symbol);
        my $frame = $*runtime.current-frame();
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$frame.id ~ $symbol};
        my $identifier = Q::Identifier.new(
            :name(Val::Str.new(:value($symbol))),
            :$frame);
        $*runtime.declare-var($identifier);
        @*declstack[*-1]{$symbol} = $decltype;
    }

    proto token statement {*}
    rule statement:my {
        my [<identifier> || <.panic("identifier")>]
        { declare(Q::Statement::My, $<identifier>.ast.name.value); }
        ['=' <EXPR>]?
    }
    rule statement:constant {
        constant <identifier>
        {
            my $symbol = $<identifier>.ast.name.value;
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
    rule statement:sub-or-macro {
        $<routine>=(sub|macro)» [<identifier> || <.panic("identifier")>]
        :my $*insub = True;
        {
            declare($<routine> eq "sub"
                        ?? Q::Statement::Sub
                        !! Q::Statement::Macro,
                    $<identifier>.ast.name.value);
        }
        <.newpad>
        '(' ~ ')' <parameterlist>
        <traitlist>
        [<blockoid>|| <.panic("block")>]:!s
        <.finishpad>
    }
    token statement:return {
        return [<.ws> <EXPR>]?
    }

    token statement:throw {
        throw [<.ws> <EXPR>]?
    }

    token statement:if {
        if <.ws> <xblock>
        [  <.ws> else <.ws>
            [
                | <else=block>
                | <else=statement:if>
            ]
        ] ?
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
    token statement:class {
        class <.ws>
        { check-feature-flag("'class' keyword", "CLASS"); }
        <identifier> <.ws>
        { declare(Q::Statement::Class, $<identifier>.ast.name.value); }
        <block>
    }

    rule traitlist {
        <trait> *
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
        <!before '{{{'> <?[{]> <.newpad> <blockoid> <.finishpad>    # } }}}, vim
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

    rule EXPR { <termish> +% [<infix> | <infix=infix-unquote>] }

    token termish { [<prefix> | <prefix=prefix-unquote>]* [<term>|<term=unquote>] <postfix>* }

    method prefix {
        my @ops = $*parser.opscope.ops<prefix>.keys;
        if /@ops/(self) -> $cur {
            return $cur."!reduce"("prefix");
        }
        return /<!>/(self);
    }

    token str { '"' ([<-["]> | '\\\\' | '\\"']*) '"' } # " you are welcome vim

    proto token term {*}
    token term:none { None» }
    token term:false { False» }
    token term:true { True» }
    token term:int { \d+ }
    token term:array { '[' ~ ']' [[<.ws> <EXPR>]* %% [\h* ','] <.ws>] }
    token term:str { <str> }
    token term:parens { '(' ~ ')' <EXPR> }
    token term:regex {
        '/' ~ '/'
        [
            { check-feature-flag("Regex syntax", "REGEX"); }
            <contents=str>
        ]
    }
    token term:quasi { quasi <.ws>
        [
            || "@" <.ws> $<qtype>=["Q::Infix"] <.ws> '{' <.ws> <infix> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Prefix"] <.ws> '{' <.ws> <prefix> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Postfix"] <.ws> '{' <.ws> <postfix> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Expr"] <.ws> '{' <.ws> <EXPR> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Identifier"] <.ws> '{' <.ws> <term:identifier> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Block"] <.ws> '{' <.ws> <block> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::CompUnit"] <.ws> '{' <.ws> [<compunit=.unquote("Q::CompUnit")> || <compunit>] <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Literal"] <.ws> '{' <.ws> [<term:int> | <term:none> | <term:str>] <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Literal::Int"] <.ws> '{' <.ws> <term:int> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Literal::None"] <.ws> '{' <.ws> <term:none> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Literal::Str"] <.ws> '{' <.ws> <term:str> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Property"] <.ws> '{' <.ws> <property> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::PropertyList"] <.ws> '{' <.ws> <propertylist> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Term"] <.ws> '{' <.ws> <term> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Term::Array"] <.ws> '{' <.ws> <term:array> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Term::Object"] <.ws> '{' <.ws> <term:object> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Term::Quasi"] <.ws> '{' <.ws> <term:quasi> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Trait"] <.ws> '{' <.ws> <trait> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::TraitList"] <.ws> '{' <.ws> <traitlist> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Statement"] <.ws> <block>
            || "@" <.ws> $<qtype>=["Q::StatementList"] <.ws> <block>
            || "@" <.ws> $<qtype>=["Q::Parameter"] <.ws> '{' <.ws> <parameter> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::ParameterList"] <.ws> '{' <.ws> <parameterlist> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::ArgumentList"] <.ws> '{' <.ws> <argumentlist> <.ws> '}'
            || "@" <.ws> $<qtype>=["Q::Unquote"] <.ws> '{' <.ws> <unquote> <.ws> '}'
            || "@" <.ws> (\S+) { die "Unknown Q type $0" } # XXX: turn into X::
            || <block>
            || <.panic("quasi")>
        ]
    }
    token term:new-object {
        new» <.ws>
        <identifier> <?{ $*runtime.maybe-get-var(~$<identifier>) ~~ Val::Type }> <.ws>
        '{' ~ '}' <propertylist>
    }
    token term:object {
        '{' ~ '}' <propertylist>
    }
    token term:identifier {
        <identifier>
    }
    token term:sub {
        sub <.ws> <identifier>?
        :my $*insub = True;
        <.newpad>
        {
            if $<identifier> {
                declare(Q::Term::Sub, $<identifier>.ast.name.value);
            }
        }
        '(' ~ ')' <parameterlist>
        <traitlist>
        <blockoid>:!s
        <.finishpad>
    }

    token propertylist { [<.ws> <property>]* %% [\h* ','] <.ws> }

    token unquote($type?) {
        '{{{'
        <EXPR>
        [:s "@" <identifier> ]?
        <?{ !$type || ($<identifier> // "") eq $type }>
        '}}}'
    }

    proto token property {*}
    rule property:str-expr { <key=str> ':' <value=EXPR> }
    rule property:identifier-expr { <identifier> ':' <value=EXPR> }
    rule property:method {
        <identifier>
        '(' ~ ')' [
            :my $*insub = True;
            <.newpad>
            <parameterlist>
        ]
        <trait> *
        <blockoid>:!s
        <.finishpad>
    }
    token property:identifier { <identifier> }

    method infix {
        my @ops = $*parser.opscope.ops<infix>.keys;
        if /@ops/(self) -> $cur {
            return $cur."!reduce"("infix");
        }
        return /<!>/(self);
    }

    rule infix-unquote {
        <unquote>
    }

    rule prefix-unquote {
        <unquote> <?{ ($<unquote><identifier> // "") eq "Q::Prefix" }>
    }

    method postfix {
        # XXX: should find a way not to special-case [] and () and .
        if /$<index>=[ <.ws> '[' ~ ']' [<.ws> <EXPR>] ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        elsif /$<call>=[ <.ws> '(' ~ ')' [<.ws> [<argumentlist=.unquote("Q::ArgumentList")> || <argumentlist>]] ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        elsif /$<prop>=[ <.ws> '.' <identifier> ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }

        my @ops = $*parser.opscope.ops<postfix>.keys;
        if /@ops/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        return /<!>/(self);
    }

    token identifier {
        <!before \d> [\w+]+ % '::'
            [ <?after \w> || <.panic("identifier")> ]
            [ [':<' [ '\\>' | '\\\\' | <-[>]> ]+ '>']
            | [':«' [ '\\»' | '\\\\' | <-[»]> ]+ '»'] ]?
    }

    rule argumentlist {
        <EXPR> *%% ','
    }

    rule parameterlist {
        [
            <parameter>
            { declare(Q::Parameter, $<parameter>[*-1]<identifier>.ast.name.value); }
        ]* %% ','
    }

    rule parameter {
        <identifier>
    }

    token ws {
        [ \s+ | '#' \N* ]*
    }
}
