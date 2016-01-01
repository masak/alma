use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        # James Bond, secret agent of the British crown
        .

    outputs
        $program,
        "",
        "comment on a separate line";
}

{
    my $program = q:to/./;
        say("James");
        # it's not as glamorous a job as it looks
        say("Bond");
        .

    outputs
        $program,
        "James\nBond\n",
        "comment between two statements";
}

{
    my $program = q:to/./;
        if 0 {              # fancy cars,
            say("yeah!");   # seductive women,
        }                   # passenger seat eject buttons
        .

    outputs
        $program,
        "",
        "comments at the end of lines";
}

done-testing;
