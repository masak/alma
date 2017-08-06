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
    my %programs =
        'say(/"abc" "def"/.fullmatch("abcdef"));' => True,
        'say(/"abc" "def"/.fullmatch("abcde"));' => False,
        'say(/"abc"? "def"?/.fullmatch(""));' => True,
        'say(/"abc"? "def"?/.fullmatch("abc"));' => True,
        'say(/"abc"? "def"?/.fullmatch("abcdef"));' => True,
        'say(/"abc"? "def"?/.fullmatch("def"));' => True,
        'say(/"abc"? "def"?/.fullmatch("defxyz"));' => False,
        'say(/"abc" "def"+/.fullmatch("abc"));' => False,
        'say(/"abc" "def"+/.fullmatch("abcdef"));' => True,
        'say(/"abc" "def"+/.fullmatch("abcdefdefdef"));' => True,
        'say(/"abc" ["def"+ "xyz"]/.fullmatch("abcdefdefdefxyz"));' => True,
        'say(/"abc" ["def"+ "xyz"]/.fullmatch("abcdefdefdefxy"));' => False,
        'say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abc|"));' => True,
        'say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcxyz|"));' => True,
        'say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcdef|"));' => True,
        'say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcdefdefdefxyz|defdef|"));' => True,
        'say(/"abc" ["def"* "xyz"? "|"]+/.fullmatch("abcdefdefdefxy|"));' => False,
        'say(/"abc" ["def" | "xyz"]+/.fullmatch("abcdefxyzdef"));' => True,
        'say(/"abc" ["def" | "xyz"]+/.fullmatch("abcdefxyzde"));' => False,
        'say(/"abc" ["def" | "xyz"]+/.fullmatch("abcdefxyzxydef"));' => False,
        ;

    for %programs.kv -> $program, $result {
        outputs $program, "$result\n", "Testing regex, $program";
    }
}

done-testing;
