use v6;
use Test;
use Alma::Test;

ensure-feature-flag("CLASS");

{
    my $program = q:to/./;
        class C {
        }

        say("alive");
        .

    outputs $program, "alive\n", "empty class declaration";
}

{
    my $program = q:to/./;
        class C {
        }

        say(C);
        .

    outputs $program, "<type C>\n", "the class declaration declares the class";
}

{
    my $program = q:to/./;
        class C {
        }

        my c = new C {};
        say(type(c));
        .

    outputs $program, "<type C>\n", "can create a new instance of the class";
}

{
    my $program = q:to/./;
        my BuiltinDict;
        BEGIN {
            BuiltinDict = Dict;
        }
        {
            class Dict {
            }

            say({} ~~ BuiltinDict);
            say({} ~~ Dict);
        }
        .

    outputs $program, "true\nfalse\n", "the `\{\}` syntax uses the built-in Dict, even when overridden";
}

{
    my $program = q:to/./;
        macro moo() {
            class C {
            }

            return quasi {
                new C {}
            }
        }

        class C {
        }

        say(moo() ~~ C);
        .

    outputs $program, "false\n", "lookup stays hygienic even when a `new C \{\}` is expanded";
}

{
    my $program = q:to/./;
        class C {
        }

        class D {
        }

        say(new D {} ~~ C);
        .

    outputs $program, "false\n", "two different classes are not type compatible";
}

{
    my $program = q:to/./;
        func class_7() {
            say("OH HAI");
        }

        class_7();
        .

    outputs $program, "OH HAI\n", "can start an expression with an identifier prefixed 'class'";
}

done-testing;
