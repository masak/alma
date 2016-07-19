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

done-testing;
