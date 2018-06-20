use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        macro statement:<whoa>() is parsed(/"whoa!"/) {
            return quasi @ Q::Statement {
                say("whoa!");
            }
        };

        whoa!;
        .

    outputs
        $program,
        "whoa!\n",
        "an is-parsed statement macro gets installed and participates in parsing";
}

done-testing;
