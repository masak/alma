use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (my (ident "n") (assign (ident "n") (int 7)))
          (stexpr (call (ident "say") (arguments (ident "n")))))
        .

    is-result $ast, "7\n", "int type works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "s") (assign (ident "s") (str "Bond")))
          (stexpr (call (ident "say") (arguments (ident "s")))))
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
        (statements
          (my (ident "n") (assign (ident "n") (array (int 1) (int 2))))
          (stexpr (call (ident "say") (arguments (ident "n")))))
        .

    is-result $ast, "[1, 2]\n", "array type works";
}

done-testing;
