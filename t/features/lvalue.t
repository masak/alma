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

done-testing;
