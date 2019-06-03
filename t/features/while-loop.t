use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my u = 3;
        while u {
            say(u);
            u = u - 1;
        }
        .

    outputs
        $program,
         "3\n2\n1\n",
        "while loop stops when the condition is false";
}

{
    my $program = q:to/./;
        my u = 3;
        while u -> x {
            say(x);
            u = u - 1;
        }
        .

    outputs
        $program,
         "3\n2\n1\n",
        "the block parameter is available from inside the loop";
}

{
    my $program = q:to/./;
        my u = 3;
        while u -> {
            u = u - 1;
        }
        say("alive");
        .

    outputs
        $program,
        "alive\n",
        "using -> without parameters in a block is allowed";
}

{
    my $program = q:to/./;
        my u = 3;
        while u -> a, b, c {
            say(u);
            u = u - 1;
        }
        say("alive");
        .

    runtime-error
        $program,
        X::ParameterMismatch,
        "while loops don't accept more than one parameter";
}

{
    my $program = q:to/./;
        my n = 4;
        while (n = n - 1) > 0 {
            if n %% 2 {
                next;
            }
            say(n);
        }
        .

    outputs $program, "3\n1\n", "`next` can skip to the next iteration of a `while` loop";
}

{
    my $program = q:to/./;
        my n = 7;
        while (n = n - 1) > 0 {
            say(n);
            if n == 3 {
                last;
            }
        }
        .

    outputs $program, "6\n5\n4\n3\n", "`last` can abort a `while` loop early";
}

done-testing;
