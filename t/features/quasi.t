use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say(quasi { 1 + 1 });
        .

    my $expected = read(
        "(statementlist (stexpr (infix:+ (int 1) (int 1))))"
    ).block.statementlist.statements.elements[0].expr.Str;
    outputs $program, "$expected\n", "Basic quasi quoting";
}

{
    my $program = q:to/./;
        macro foo() {
            return quasi {
                say("OH HAI");
            }
        }

        foo();
        .

    outputs $program, "OH HAI\n", "Quasi quoting works for macro return value";
}

{
    my $program = q:to/./;
        macro foo() {
            my x = 7;
            return quasi {
                say(x);
            }
        }

        foo();
        .

    outputs $program, "7\n", "a variable is looked up in the quasi's environment";
}

{
    my $program = q:to/./;
        macro moo() {
            sub infix:<**>(l, r) {
                return l ~ " to the " ~ r;
            }
            return quasi {
                say("pedal" ** "metal");
            }
        }

        moo();
        .

    outputs
        $program,
        "pedal to the metal\n",
        "operator used in quasi block carries its original environement";
}

{
    my $program = q:to/./;
        macro gah() {
            return quasi { say(2 + 2) }
        }

        {
            sub infix:<+>(l, r) { return "lol, pwnd!" }
            gah()
        }
        .

    outputs
        $program,
        "4\n",
        "operators in quasi aren't unhygienically overriden by mainline environment";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Infix { + }));
        .

    outputs $program, "<type Q::Infix::Addition>\n", "quasi @ Q::Infix";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Prefix { - }));
        .

    outputs $program, "<type Q::Prefix::Minus>\n", "quasi @ Q::Prefix";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Postfix { .foo }));
        .

    outputs $program, "<type Q::Postfix::Property>\n", "quasi @ Q::Postfix";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Expr { 2 + (2 + 2) + -2 + [2][2] }));
        .

    outputs $program, "<type Q::Infix::Addition>\n", "quasi @ Q::Expr";
}

{
    my $program = q:to/./;
        my foo;
        say(type(quasi @ Q::Identifier { foo }));
        .

    outputs $program, "<type Q::Identifier>\n", "quasi @ Q::Identifier";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Block { { say("Bond") } }));
        .

    outputs $program, "<type Q::Block>\n", "quasi @ Q::Block";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::CompUnit { say("James"); }));
        .

    outputs $program, "<type Q::CompUnit>\n", "quasi @ Q::CompUnit";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Literal { 7 }));
        say(type(quasi @ Q::Literal { None }));
        say(type(quasi @ Q::Literal { "James Bond" }));
        .

    outputs $program,
        "<type Q::Literal::Int>\n<type Q::Literal::None>\n<type Q::Literal::Str>\n",
        "quasi @ Q::Literal";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Literal::Int { 7 }));
        .

    outputs $program, "<type Q::Literal::Int>\n", "quasi @ Q::Literal::Int";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Literal::None { None }));
        .

    outputs $program, "<type Q::Literal::None>\n", "quasi @ Q::Literal::None";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Literal::Str { "James Bond" }));
        .

    outputs $program, "<type Q::Literal::Str>\n", "quasi @ Q::Literal::Str";
}

{
    my $program = q:to/./;
        my prop;
        say(type(quasi @ Q::Property { key: "value" }));
        say(type(quasi @ Q::Property { "key": "value" }));
        say(type(quasi @ Q::Property { fn() {} }));
        say(type(quasi @ Q::Property { prop }));
        .

    outputs $program, "<type Q::Property>\n" x 4, "quasi @ Q::Property";
}

{
    my $program = q:to/./;
        my prop;
        my q = quasi @ Q::PropertyList {
            key1: "value",
            "key2": "value",
            fn() {},
            prop
        };

        say(type(q));
        say(q.properties.elems());
        .

    outputs $program, "<type Q::PropertyList>\n4\n", "quasi @ Q::PropertyList";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Term { 7 }));
        say(type(quasi @ Q::Term { None }));
        say(type(quasi @ Q::Term { "James Bond" }));
        say(type(quasi @ Q::Term { [0, 0, 7] }));
        say(type(quasi @ Q::Term { new Object { james: "Bond" } }));
        say(type(quasi @ Q::Term { quasi { say("oh, james!") } }));
        say(type(quasi @ Q::Term { (0 + 0 + 7) }));
        .

    outputs $program,
        <Literal::Int Literal::None Literal::Str
            Term::Array Term::Object Term::Quasi
            Infix::Addition>\
            .map({ "<type Q::$_>\n" }).join,
        "quasi @ Q::Term";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Term::Array { [0, 0, 7] }));
        .

    outputs $program, "<type Q::Term::Array>\n", "quasi @ Q::Term::Array";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Term::Object { new Object { james: "Bond" } }));
        .

    outputs $program, "<type Q::Term::Object>\n", "quasi @ Q::Term::Object";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Term::Quasi { quasi { say("oh, james!") } }));
        .

    outputs $program, "<type Q::Term::Quasi>\n", "quasi @ Q::Term::Quasi";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Trait { is equal(infix:<+>) }));
        .

    outputs $program, "<type Q::Trait>\n", "quasi @ Q::Trait";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::TraitList { is equal(infix:<+>) is assoc("right") }));
        .

    outputs $program, "<type Q::TraitList>\n", "quasi @ Q::TraitList";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Statement { say("james") }));
        say(type(quasi @ Q::Statement { say("bond"); }));
        .

    outputs $program, "<type Q::Statement::Expr>\n" x 2, "quasi @ Q::Statement";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::StatementList { say("james"); say("bond") }));
        say(type(quasi @ Q::StatementList { say("james"); say("bond"); }));
        .

    outputs $program, "<type Q::StatementList>\n" x 2, "quasi @ Q::StatementList";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::Parameter { foo }));
        .

    outputs $program, "<type Q::Parameter>\n", "quasi @ Q::Parameter";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::ParameterList { james, tiberius, bond }));
        .

    outputs $program, "<type Q::ParameterList>\n", "quasi @ Q::ParameterList";
}

{
    my $program = q:to/./;
        say(type(quasi @ Q::ArgumentList { 1, "foo", [0, 0, 7] }));
        .

    outputs $program, "<type Q::ArgumentList>\n", "quasi @ Q::ArgumentList";
}

{
    my $program = q:to/./;
        my q = quasi { say("oh, james") };
        say(type(quasi @ Q::Unquote { {{{q}}} }));
        .

    outputs $program, "<type Q::Unquote>\n", "quasi @ Q::Unquote";
}

{
    my $program = q:to/./;
        my q1 = quasi @ Q::Statement { my x; };
        my q2 = quasi @ Q::Statement { my x; };
        say("alive");
        .

    outputs $program, "alive\n", "Q::Statement quasis don't leak (I)";
}

{
    my $program = q:to/./;
        my q1 = quasi @ Q::Statement { my x; };
        say(x);
        .

    parse-error $program, X::Undeclared, "Q::Statement quasis don't leak (II)";
}

{
    my $program = q:to/./;
        macro moo() {
            return quasi {
                say(1);
                say(2);
            }
        };

        sub ignore(x) {}

        ignore(moo());
        .

    outputs $program, "1\n2\n", "the value of an injected quasi can be passed around the program";
}

{
    my $program = q:to/./;
        macro moo() {
            return quasi {
                say(1);
                "Bond";
            }
        };

        say(moo());
        .

    outputs $program, "1\nBond\n", "the last statement of a quasi becomes the value of the quasi";
}

done-testing;
