use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        export func greet(name) {
            say("Good evening, Mr " ~ name);
        }
        greet("Bond");
        .

    outputs $program, "Good evening, Mr Bond\n", "export syntax works for functions";
}

{
    my $program = q:to/./;
        export macro moo() {
            say("Macro!");
        }
        moo();
        .

    outputs $program, "Macro!\n", "export syntax works for macros";
}

{
    my $program = q:to/./;
        export my name = "Bond";

        say(name);
        .

    outputs $program, "Bond\n", "export syntax works for 'my' variables";
}

{
    my $program = q:to/./;
        export 2 + my name = "Bond";
        .

    parse-error $program,
        X::Export::Nothing,
        "export syntax is not allowed if 'my' variable is not on the left";
}

{
    my $program = q:to/./;
        export "but there was nothing there to export";
        .

    parse-error $program,
        X::Export::Nothing,
        "export syntax is not allowed if the 'my' variable is missing";
}

done-testing;
