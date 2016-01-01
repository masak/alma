use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say(quasi { 1 + 1 });
        .

    my $expected = read(
        "(statementlist (stexpr (infix:<+> (int 1) (int 1))))"
    ).block.Str;
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
        constant greeting_ast = Q::Literal::Str { value: "Mr Bond!" };

        macro foo() {
            return quasi {
                say({{{greeting_ast}}});
            }
        }

        foo();
        .

    outputs $program, "Mr Bond!\n", "very basic unquote";
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
        macro foo(expr) {
            my x = "oh noes";
            return quasi {
                say({{{expr}}});
            }
        }

        my x = "yay";
        foo(x);
        .

    outputs $program, "yay\n", "macro arguments also carry their original environment";
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

done-testing;
