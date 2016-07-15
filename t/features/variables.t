use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "u"))
          (stexpr (postfix:() (identifier "say") (argumentlist (identifier "u")))))
        .

    is-result $ast, "None\n", "variables can be declared without being assigned";
}

done-testing;
