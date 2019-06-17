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
        $*runtime.enter($*runtime.current-frame, Val::Dict.new, Q::StatementList.new);
    } }

    token finishpad { <?> {
        @*declstack.pop;
        $*parser.pop-opscope;
    } }

    rule statementlist {
        <.semicolon>* [<possibly-decorated-statement>[<.semicolon>+|<.eat_terminator>] ]*
    }

    method panic($what) {
        die X::Syntax::Missing.new(:$what);
    }

    our sub declare(Q::Declaration $decltype, Str $symbol) {
        die X::Redeclaration.new(:$symbol)
            if $*runtime.declared-locally($symbol);
        my $frame = $*runtime.current-frame();
        die X::Redeclaration::Outer.new(:$symbol)
            if %*assigned{$frame.WHICH ~ $symbol};
        my $identifier = Q::Identifier.new(
            :name(Val::Str.new(:value($symbol)))
        );
        $*runtime.declare-var($identifier);
        @*declstack[*-1]{$symbol} = $decltype;
    }

    rule possibly-decorated-statement {
        :my @*DECORATORS;
        <decorator> *
        <statement>}

    proto rule statement {*}
    token statement:expr {
        $<export>=(export \s+)?
        <!before <!before '{{{'> '{'>   # } }}}, you're welcome vim
        <EXPR>
    }
    token statement:block { <pblock> }
    rule statement:func-or-macro {
        [export\s+]?$<routine>=(func|macro)» [<identifier> || <.panic("identifier")>]
        :my $*in-routine = True;
        :my $*in-loop = False;
        {
            declare($<routine> eq "func"
                        ?? Q::Statement::Func
                        !! Q::Statement::Macro,
                    $<identifier>.ast.name.value);
        }
        <.newpad>
        {
            $*parser.opscope.maybe-install($<identifier>.ast.name, @*DECORATORS);
        }
        '(' ~ ')' <parameterlist>
        [<blockoid>|| <.panic("block")>]:!s
        <.finishpad>
    }
    token statement:return {
        return» [<.ws> <EXPR>]?
    }

    token statement:throw {
        throw» [<.ws> <EXPR>]?
    }

    token statement:next {
        next»
    }

    token statement:last {
        last»
    }

    token statement:if {
        if» <.ws> <xblock>
        [  <.ws> else <.ws>
            [
                | <else=.pblock>
                | <else=.statement:if>
            ]
        ] ?
    }

    token statement:for {
        for» <.ws> <EXPR>
        :my $*in-loop = True;
        <pblock>
    }
    token statement:while {
        while» <.ws> <EXPR>
        :my $*in-loop = True;
        <pblock>
    }
    token statement:BEGIN {
        BEGIN» <.ws> <statement>
    }
    token statement:class {
        class» <.ws>
        { check-feature-flag("'class' keyword", "CLASS"); }
        <identifier> <.ws>
        { declare(Q::Statement::Class, $<identifier>.ast.name.value); }
        <block>
    }

    rule decorator {
        '@'<identifier>
        ['(' ~ ')' <argumentlist>]?
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

    token semicolon {
        <.ws> ';'
    }

    token eat_terminator {
        || <?after '}'> $$
        || <.ws> <?before '}'>
        || <.ws> $
    }

    rule EXPR { <termish> +% [<infix> | <infix=infix-unquote>] }

    rule termish { [<prefix> | <prefix=prefix-unquote>] * [<term>|<term=unquote>] <postfix> * }

    method prefix {
        my @ops = $*parser.opscope.ops<prefix>.keys;
        if /@ops [<!after \w> | <!before \w>]/(self) -> $cur {
            return $cur."!reduce"("prefix");
        }
        return /<!>/(self);
    }

    token str { '"' ([<-["]> | '\\\\' | '\\"']*) '"' } # " you are welcome vim

    rule regex-part {
        <regex-group> + %% '|'
    }

    rule regex-group {
        <regex-quantified> +
    }

    token regex-quantified {
        <regex-fragment> $<quantifier>=<[+ * ?]>?
    }

    proto token regex-fragment {*}
    token regex-fragment:str {
        <str>
    }
    token regex-fragment:identifier {
        # XXX: should be term:identifier
        <identifier>
    }
    token regex-fragment:call {
        '<' ~ '>'
        # XXX: should be term:identifier
        <identifier>
    }
    rule regex-fragment:group { ''
        '[' ~ ']'
        <regex-part>
    }

    proto token term {*}
    token term:none { none» }
    token term:false { false» }
    token term:true { true» }
    token term:int { \d+ }
    token term:array { '[' ~ ']' [[<.ws> <EXPR>]* %% [\h* ','] <.ws>] }
    token term:str { <str> }
    token term:parens { '(' ~ ')' <EXPR> }
    token term:regex {
        '/' ~ '/'
        [
            { check-feature-flag("Regex syntax", "REGEX"); }
            <regex-part>
        ]
    }
    token term:quasi { quasi <.ws>
        [
            || "<" <.ws> $<qtype>=["Q.Infix"] ">" <.ws> '{' <.ws> <infix> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Prefix"] ">" <.ws> '{' <.ws> <prefix> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Postfix"] ">" <.ws> '{' <.ws> <postfix> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Expr"] ">" <.ws> '{' <.ws> <EXPR> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Identifier"] ">" <.ws> '{' <.ws> <identifier> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Block"] ">" <.ws> '{' <.ws> <block> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.CompUnit"] ">" <.ws> '{' <.ws> [<compunit=.unquote("Q.CompUnit")> || <compunit>] <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Literal"] ">" <.ws> '{' <.ws> [<term:int> | <term:none> | <term:str>] <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Literal.Int"] ">" <.ws> '{' <.ws> <term:int> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Literal.None"] ">" <.ws> '{' <.ws> <term:none> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Literal.Str"] ">" <.ws> '{' <.ws> <term:str> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Property"] ">" <.ws> '{' <.ws> <property> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.PropertyList"] ">" <.ws> '{' <.ws> <propertylist> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Term"] ">" <.ws> '{' <.ws> <term> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Term.Array"] ">" <.ws> '{' <.ws> <term:array> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Term.Dict"] ">" <.ws> '{' <.ws> <term:object> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Term.Quasi"] ">" <.ws> '{' <.ws> <term:quasi> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Statement"] ">" <.ws> <block>
            || "<" <.ws> $<qtype>=["Q.StatementList"] ">" <.ws> <block>
            || "<" <.ws> $<qtype>=["Q.Parameter"] ">" <.ws> '{' <.ws> <parameter> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.ParameterList"] ">" <.ws> '{' <.ws> <parameterlist> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.ArgumentList"] ">" <.ws> '{' <.ws> <argumentlist> <.ws> '}'
            || "<" <.ws> $<qtype>=["Q.Unquote"] ">" <.ws> '{' <.ws> <unquote> <.ws> '}'
            || "<" <.ws> (<[\S]-[>]>+) ">" { die "Unknown Q type $0" } # XXX: turn into X::
            || <block>
            || <.panic("quasi")>
        ]
    }
    token term:new-object {
        new» <.ws>
        # XXX: Deliberately introducing a bug here. Sorry!
        # The first of the below identifiers should be a term:identifier, and the lookup
        # should adapt to that fact. #250 would help sort this out. We're getting away
        # with this because we're essentially missing a tricky-enough test, probably
        # involving quasis and/or macros.
        <identifier>+ % [<.ws> "." <.ws>] <?{
            my $type;
            [&&] $<identifier>.map(&prefix:<~>).map(-> $identifier {
                $type = $++
                    ?? $*runtime.property($type, $identifier)
                    !! $*runtime.maybe-get-var($identifier);
                $type ~~ Val::Type;
            });
        }> <.ws>
        '{' ~ '}' <propertylist>
    }
    token term:dict {
        '{' ~ '}' <propertylist>
    }
    token term:identifier {
        <identifier>
    }
    token term:func {
        func» <.ws> <identifier>?
        :my $*in-routine = True;
        <.newpad>
        {
            if $<identifier> {
                declare(Q::Term::Func, $<identifier>.ast.name.value);
            }
        }
        '(' ~ ')' <parameterlist>
        <.ws>
        <blockoid>:!s
        <.finishpad>
    }
    token term:my {
        my» <.ws> [<identifier> || <.panic("identifier")>]
        { declare(Q::Term::My, $<identifier>.ast.name.value); }
    }


    token propertylist { [<.ws> <property>]* %% [\h* ','] <.ws> }

    token unquote($type?) {
        '{{{'
        [:s <identifier> +% "." "@" ]?
        <?{ !$type || $<identifier>.join(".") eq $type }>
        <EXPR>
        '}}}'
    }

    proto token property {*}
    rule property:str-expr { <key=str> ':' <value=EXPR> }
    rule property:identifier-expr { <identifier> ':' <value=EXPR> }
    rule property:method {
        <identifier>
        '(' ~ ')' [
            :my $*in-routine = True;
            <.newpad>
            <parameterlist>
        ]
        <blockoid>:!s
        <.finishpad>
    }
    token property:identifier {
        <identifier>
    }

    method infix {
        my @ops = $*parser.opscope.ops<infix>.keys;
        if /@ops [<!after \w> | <!before \w>]/(self) -> $cur {
            return $cur."!reduce"("infix");
        }
        return /<!>/(self);
    }

    rule infix-unquote {
        <unquote>
    }

    rule prefix-unquote {
        <unquote> <?{ $<unquote><identifier>.join(".") eq "Q.Prefix" }>
    }

    method postfix {
        # XXX: should find a way not to special-case [] and () and .
        if /$<index>=[ <.ws> '[' ~ ']' [<.ws> <EXPR>] ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        elsif /$<call>=[ <.ws> '(' ~ ')' [<.ws> [<argumentlist=.unquote("Q.ArgumentList")> || <argumentlist>]] ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        elsif /$<prop>=[ <.ws> '.' <identifier> ]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }

        my @ops = $*parser.opscope.ops<postfix>.keys;
        if /@ops [<!after \w> | <!before \w>]/(self) -> $cur {
            return $cur."!reduce"("postfix");
        }
        return /<!>/(self);
    }

    token identifier {
        <!before \d> \w+
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
