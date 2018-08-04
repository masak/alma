use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my u;
        say(u);
        .

    outputs $program, "None\n", "variables can be declared without being assigned";
}

done-testing;
