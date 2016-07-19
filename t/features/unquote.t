use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        constant greeting_ast = new Q::Literal::Str { value: "Mr Bond!" };

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
            my q = quasi @ Q::Infix { + };
            return quasi { say(2 {{{q @ Q::Infix}}} 2) };
        }

        moo();
        .

    outputs $program, "4\n", "unquote @ Q::Infix";
}

{
    my $program = q:to/./;
        macro moo() {
            my q = quasi @ Q::Term { "foo" };
            return quasi { say(2 {{{q @ Q::Infix}}} 2) };
        }

        moo();
        .

    parse-error $program,
        X::TypeCheck,
        "can't put a non-infix in a Q::Infix unquote";
}

{
    my $program = q:to/./;
        macro moo() {
            my q = quasi @ Q::Infix { + };
            return quasi { say(2 {{{q @ Q::Term}}} 2) };
        }

        moo();
        .

    parse-error $program,
        X::TypeCheck,
        "can't put a non-infix unquote in infix operator position (explicit)";
}

{
    my $program = q:to/./;
        macro moo() {
            my q = quasi @ Q::Infix { + };
            return quasi { say(2 {{{q}}} 2) };
        }

        moo();
        .

    parse-error $program,
        X::TypeCheck,
        "can't put a non-infix unquote in infix operator position (implicit)";
}

{
    my $program = q:to/./;
        macro moo() {
            my q = quasi @ Q::Prefix { - };
            return quasi { say({{{q @ Q::Prefix}}} 17) };
        }

        moo();
        .

    outputs $program, "-17\n", "unquote @ Q::Prefix";
}

{
    my $program = q:to/./;
        macro moo() {
            my q = quasi @ Q::Term { "foo" };
            return quasi { say({{{q @ Q::Prefix}}} 17) };
        }

        moo();
        .

    parse-error $program,
        X::TypeCheck,
        "can't put a non-prefix in a Q::Prefix unquote";
}

{
    my $program = q:to/./;
        sub foo(a, b, c) {
            say(a);
            say(b);
            say(c);
        }

        macro moo() {
            my q = quasi @ Q::ArgumentList { 1, "foo", [0, 0, 7] };
            return quasi { foo({{{q @ Q::ArgumentList}}}) };
        }

        moo();
        .

    outputs $program, "1\nfoo\n[0, 0, 7]\n", "unquote @ Q::ArgumentList";
}

{
    my $program = q:to/./;
        my q = quasi @ Q::CompUnit { say("James"); };
        say(type(quasi @ Q::CompUnit { {{{q @ Q::CompUnit}}} }));
        .

    outputs $program, "<type Q::CompUnit>\n", "unquote @ Q::CompUnit";
}

done-testing;
