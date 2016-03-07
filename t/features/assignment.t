use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2)))
          (stexpr (infix:<=> (postfix:<[]> (identifier "a") (int 1)) (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a")))))
        .

    is-result $ast, "[1, \"Bond\"]\n", "can assign to an element of an array (I)";
}

{
    outputs '
        my a = [1, 2];
        a[1] = "Bond";
        say(a);',

        qq![1, "Bond"]\n!,

        "can assign to an element of an array (II)";
}

done-testing;
