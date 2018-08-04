use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        {
            say("OH HAI from inside block");
        }
        .

    outputs $program, "OH HAI from inside block\n", "immediate blocks work";
}

{
    my $program = q:to/./;
        my x = "one";
        say(x);
        {
            my x = "two";
            say(x);
        }
        say(x);
        .

    outputs $program, "one\ntwo\none\n", "blocks have their own variable scope";
}

done-testing;
