use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        macro swap(x, y) is succinct {
            my t = x;
            x = y;
            y = t;
        }

        my a = 1;
        my b = 2;

        swap(a, b);

        say(a);
        say(b);
        .

    outputs
        $program,
        "2\n1\n",
        "the `is succinct` trait generates a quasi and (appropriate) unquotes";
}

done-testing;
