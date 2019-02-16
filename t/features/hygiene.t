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

done-testing;
