use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say(quasi { 1 + 1 });
        .

    outputs $program, read("(block (paramlist) (stmtlist (stexpr (+ (int 1) (int 1)))))") ~ "\n",
        "Basic quasi quoting";
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
        constant greeting_ast = Q::Literal::Str("Mr Bond!");

        macro foo() {
            return quasi {
                say({{{greeting_ast}}});
            }
        }

        foo();
        .

    outputs $program, "Mr Bond!\n", "very basic unquote";
}

done-testing;
