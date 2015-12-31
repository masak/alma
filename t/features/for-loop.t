use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2)) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "i"))))))))
        .

    is-result $ast, "i\ni\n", "for-loops without parameters iterate over an array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2)) (block (parameterlist (param (identifier "i"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "i"))))))))
        .

    is-result $ast, "1\n2\n", "for-loops with 1 param iterate over an array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2) (int 3) (int 4)) (block (parameterlist (param (identifier "i")) (param (identifier "j"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "i"))))
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "j"))))))))
        .

    is-result $ast, "1\n2\n3\n4\n", "for-loops with more parameters iterate over an array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (for (array (int 1) (int 2)) (block (parameterlist) (stmtlist
            (my (identifier "r") (int 3))
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "r"))))))))
        .

    is-result $ast, "3\n3\n", "variable declarations work inside of for loop without parameters";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (identifier "a") (array (int 1) (int 2) (int 3)))
          (for (identifier "a") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "."))))))))
        .

    is-result $ast, ".\n.\n.\n", "can loop over variable, not just literal array";
}

done-testing;
