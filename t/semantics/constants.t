use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say("runtime");
        constant C = 4;
        BEGIN {
            say(C);
        }
        .

    outputs
        $program,
        "4\nruntime\n",
        "constants are assigned and visible at BEGIN time";
}

{
    my $program = q:to/./;
        constant C = -9;
        say(C);
        .

    outputs
        $program,
        "-9\n",
        "constants are visible from runtime";
}

{
    my $program = q:to/./;
        constant C = 1;
        constant D = C + 1;
        say(D);
        .

    outputs
        $program,
        "2\n",
        "constants are visible from other constants";
}

done-testing;
