use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say(1);
        say(1 + 2);
        say(1 + 2 + 3);

        my a;
        say(a = 2);
        say(a);
        say(a = 2 + 3);
        say(a);
        say(-1);
        say(--1);
        say(a = 2 + 3 == 4);
        say(a);
        say(a = ["a", "b", "c"]);
        say(a[2]);
        say(1 + (2 + 3));
        .

    outputs $program,
        qq[1\n3\n6\n2\n2\n5\n5\n-1\n1\nFalse\nFalse\n["a", "b", "c"]\nc\n6\n],
        "various expressions work";
}

done-testing;
