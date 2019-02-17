use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        macro moo() {
            my x = "OH HAI";
            return quasi {
                say(x);
            }
        }

        moo();
        .

    outputs
        $program,
        "OH HAI\n",
        "quasis remember variables from their surrounding macro";
}

{
    my $program = q:to/./;
        macro moo() {
            return quasi {
                my x = "OH HAI";
                say(x);
            }
        }

        moo();
        .

    outputs
        $program,
        "OH HAI\n",
        "variables can be declared as usual inside of a quasi (and survive)";
}

done-testing;
