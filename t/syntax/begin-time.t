use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        sub foo() {
            say(7);
        }

        BEGIN { foo() }
        .

    outputs
        $program,
        "7\n",
        "calling a sub at BEGIN time works";
}

done;
