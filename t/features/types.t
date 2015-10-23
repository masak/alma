use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "n") (int 7))
          (stexpr (call (ident "say") (arglist (ident "n")))))
        .

    is-result $ast, "7\n", "int type works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "s") (str "Bond"))
          (stexpr (call (ident "say") (arglist (ident "s")))))
        .

    is-result $ast, "Bond\n", "str type works";
}

{
    outputs 'say("Mr \"Bond")', qq[Mr "Bond\n], qq[\\" gets unescaped correctly to "];
    outputs 'say(chars("Mr \"Bond"))', qq[8\n], qq[...and counts as one character];
    outputs 'say("Mr \\\\Bond")', qq[Mr \\Bond\n], qq[\\\\ gets unescaped correctly to \\];
    outputs 'say(chars("Mr \\Bond"))', qq[8\n], qq[...and counts as one character];
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "n") (array (int 1) (int 2)))
          (stexpr (call (ident "say") (arglist (ident "n")))))
        .

    is-result $ast, "[1, 2]\n", "array type works";
}

{
    outputs 'say(str([1, 2, "foo"]))', qq|[1, 2, "foo"]\n|,
        "strings inside arrays get quoted";

    outputs 'say([1, 2, "foo"])', qq|[1, 2, "foo"]\n|,
        "...and it works even without explicit str() coercion";

    outputs qq|say(["'\\"\\\\"])|, qq|["'\\"\\\\"]\n|,
        "double quotes and backslashes are escaped properly in strings in arrays";

    outputs 'say([1, [2, "foo"]])', qq|[1, [2, "foo"]]\n|,
        "still does the right thing one level down";
}

done-testing;
