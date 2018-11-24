use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my x = "hello";

        my L = lvalue(x);
        L.write("OH HAI");

        say(x);
        .

    outputs $program, "OH HAI\n", "the lvalue macro allows us to access a variable's Location";
}

{
    my $program = q:to/./;
        my y = "Mr. Bond";

        my L = lvalue(y);
        L.write("007");

        say(y);
        .

    outputs $program, "007\n", "same but with a different variable";
}

done-testing;
