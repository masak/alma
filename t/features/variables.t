use v6;
use Test;
use Alma::Test;

{
    my $program = q:to/./;
        my u;
        say(u);
        .

    outputs $program, "none\n", "variables can be declared without being assigned";
}

done-testing;
