use v6;
use Test;
use _007::Test;

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
        my BuiltinObject;
        BEGIN {
            BuiltinObject = Object;
        }
        {
            class Object {
            }

            say({} ~~ BuiltinObject);
            say({} ~~ Object);
        }
        .

    outputs $program, "true\nfalse\n", "the `\{\}` syntax uses the built-in Object, even when overridden";
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

done-testing;
