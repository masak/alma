use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2)) (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "i"))))))))
        .

    is-result $ast, "i\ni\n", "for-loops without params iterate over an array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2)) (block (paramlist (ident "i")) (stmtlist
            (stexpr (call (ident "say") (arglist (ident "i"))))))))
        .

    is-result $ast, "1\n2\n", "for-loops with 1 param iterate over an array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2) (int 3) (int 4)) (block (paramlist (ident "i") (ident "j")) (stmtlist
            (stexpr (call (ident "say") (arglist (ident "i"))))
            (stexpr (call (ident "say") (arglist (ident "j"))))))))
        .

    is-result $ast, "1\n2\n3\n4\n", "for-loops with more params iterate over an array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2)) (block (paramlist) (stmtlist
            (my (ident "r") (int 3))
            (stexpr (call (ident "say") (arglist (ident "r"))))))))
        .

    is-result $ast, "3\n3\n", "variable declarations work inside of for loop without parameters";
}

done-testing;
