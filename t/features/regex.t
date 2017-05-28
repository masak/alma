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

{
    my $program = q:to/./;
        say(/"Blofeld"/.fullmatch("Blofeld"));
        say(/"Blofeld"/.fullmatch("Bond"));
        say(/"Blofeld"/.fullmatch("this is Blofeld's work, I know it"));
        .

    outputs $program, "True\nFalse\nFalse\n", "the .fullmatch method matches the whole string";
}

{
    my $program = q:to/./;
        say(/"Blofeld"/.search("Blofeld"));
        say(/"Blofeld"/.search("Bond"));
        say(/"Blofeld"/.search("this is Blofeld's work, I know it"));
        .

    outputs $program, "True\nFalse\nTrue\n", "the .search method matches part of the string";
}

done-testing;
