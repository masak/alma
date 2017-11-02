use v6;
use Test;
use _007::Test;

ensure-feature-flag("REGEX");

{
    my @regexes =
      '/"hey"/',
      '/"/"/',
      '/ ["abc"] /',
      '/[ "abc" ]/',
      '/"abc" "def"+/',
      '/"a"+ "b"? "c"*/',
    ;
    for @regexes -> $regex {
        my $program = qq:to/./;
            my val = $regex;
            .
        outputs $program, "", "Regex $regex parses correctly",
    }
}

{
    my $program = q:to/./;
        say(!!/"hey"/);
        .

    outputs $program, "True\n", "Regexes are truthy";
}
{
    my @programs =
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

        'say(/"abc" ["def" | "xyz"]+/.search("abcdefxyzdef"));' => True,
        'say(/"abc" ["def" | "xyz"]+/.search("hello abcdefxyzdef"));' => True,
        'say(/"abc" ["def" | "xyz"]+/.search("abcdefxyzdef world"));' => True,
        'say(/"abc" ["def" | "xyz"]+/.search("hello abcdefxyzdef world"));' => True,
        'say(/"abc" ["def" | "xyz"]+/.search("abcdefxyzxydef"));' => True, # this is a failing case for fullmatch, but search will just stop matching after failing on "xy"
        ;

    for @programs -> $program {
        my $code = $program.key;
        my $expected = $program.value;
        outputs $code, "$expected\n", "Testing regex, program: $code";
    }
}

done-testing;
