use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my n = 7;
        say(n);
        .

    outputs $program, "7\n", "int type works";
}

{
    my $program = q:to/./;
        my s = "Bond";
        say(s);
        .

    outputs $program, "Bond\n", "str type works";
}

{
    outputs 'say("Mr \"Bond")', qq[Mr "Bond\n], qq[\\" gets unescaped correctly to " (#23)];
    outputs 'say("Mr \"Bond".chars())', qq[8\n], qq[...and counts as one character (#23)];
    outputs 'say("Mr \\\\Bond")', qq[Mr \\Bond\n], qq[\\\\ gets unescaped correctly to \\ (#23)];
    outputs 'say("Mr \\Bond".chars())', qq[8\n], qq[...and counts as one character (#23)];
}

{
    my $program = q:to/./;
        my a = [1, 2];
        say(a);
        .

    outputs $program, "[1, 2]\n", "array type works";
}

{
    outputs 'say(~[1, 2, "foo"])', qq|[1, 2, "foo"]\n|,
        "strings inside arrays get quoted (#6)";

    outputs 'say([1, 2, "foo"])', qq|[1, 2, "foo"]\n|,
        "...and it works even without explicit prefix:<~> coercion (#6)";

    outputs qq|say(["'\\"\\\\"])|, qq|["'\\"\\\\"]\n|,
        "double quotes and backslashes are escaped properly in strings in arrays (#6)";

    outputs 'say([1, [2, "foo"]])', qq|[1, [2, "foo"]]\n|,
        "still does the right thing one level down (#6)";
}

{
    outputs 'say(type(7).name)', "Int\n",
        "type(7).name is 'Int'";

    outputs 'say(type(type(7)).name)', "Type\n",
        "type(type(7)).name is 'Type'";
}

{
    my $program = q:to/./;
        new Q.Literal {}
        .

    parse-error
        $program,
        X::Uninstantiable,
        "abstract Q types are uninstantiable (#140)";
}

{
    outputs 'say(Q.name)', "Q\n",
        "Q is a built-in type (#201)";
}

done-testing;
