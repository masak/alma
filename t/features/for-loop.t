use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        for [1, 2] {
            say("i");
        }
        .

    outputs $program, "i\ni\n", "for loops without parameters iterate over an array";
}

{
    my $program = q:to/./;
        for [1, 2] -> i {
            say(i);
        }
        .

    outputs $program, "1\n2\n", "for loops with 1 param iterate over an array";
}

{
    my $program = q:to/./;
        for [1, 2, 3, 4] -> i, j {
        }
        .

    runtime-error $program,
        X::ParameterMismatch,
        "for-loops with more parameters are not supported";
}

{
    my $program = q:to/./;
        for [1, 2] {
            my r = 3;
            say(r);
        }
        .

    outputs $program, "3\n3\n", "variable declarations work inside of for loop without parameters";
}

{
    my $program = q:to/./;
        my a = [1, 2, 3];
        for a {
            say(".");
        }
        .

    outputs $program, ".\n.\n.\n", "can loop over variable, not just literal array";
}

done-testing;
