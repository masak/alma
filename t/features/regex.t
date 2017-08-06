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
        say(/"abc" "def"/.fullmatch("abcdef")); #True
        say(/"abc" "def"/.fullmatch("abcde")); #False
        say(/"abc"? "def"?/.fullmatch("")); #True
        say(/"abc"? "def"?/.fullmatch("abc")); #True
        say(/"abc"? "def"?/.fullmatch("abcdef")); #True
        say(/"abc"? "def"?/.fullmatch("def")); #True
        say(/"abc"? "def"?/.fullmatch("defxyz")); #False
        say(/"abc" "def"+/.fullmatch("abc")); #False
        say(/"abc" "def"+/.fullmatch("abcdef")); #True
        say(/"abc" "def"+/.fullmatch("abcdefdefdef")); #True
        say(/"abc" ["def"+ "xyz"]/.fullmatch("abcdefdefdefxyz")); #True
        say(/"abc" ["def"+ "xyz"]/.fullmatch("abcdefdefdefxy")); #False
        say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abc|")); #True
        say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcxyz|")); #True
        say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcdef|")); #True
        say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcdefdefdefxyz|defdef|")); #True
        say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcdefdefdefxy|")); #False
        .

    my $expected = ($program ~~ m:g['#' (\w+)]).map(*.[0].Str);
    #my $expected = $program.lines.map(*.split('#')[1]);

    outputs $program, $expected.join("\n")~"\n", "Some regexes test";
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
