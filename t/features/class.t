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
        constant Builtin::Object = Object;
        {
            class Object {
            }

            say({} ~~ Builtin::Object);
            say({} ~~ Object);
        }
        .

    outputs $program, "True\nFalse\n", "the `\{\}` syntax uses the built-in Object, even when overridden";
}

done-testing;
