use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "u"))
          (stexpr (postfix:<()> (ident "say") (arglist (ident "u")))))
        .

    is-result $ast, "None\n", "variables can be declared without being assigned";
}

done-testing;
