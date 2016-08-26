use v6;
use Test;
use _007::Test;

ensure-feature-flag("REGEX");

{
    my $program = q:to/./;
        my val = /"hey"/;
        .

    outputs $program, "", "Regexes parse correctly";
}

{
    my $program = q:to/./;
        say(!!/"hey"/);
        .

    outputs $program, "True\n", "Regexes are truthy";
}

done-testing;
