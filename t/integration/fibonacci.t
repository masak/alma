use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "fib") (block (parameterlist (param (identifier "n"))) (stmtlist
            (if (infix:<==> (identifier "n") (int 0)) (block (parameterlist) (stmtlist
              (return (int 1)))))
            (if (infix:<==> (identifier "n") (int 1)) (block (parameterlist) (stmtlist
              (return (int 1)))))
            (return (infix:<+> (postfix:<()> (identifier "fib") (arglist (infix:<+> (identifier "n") (prefix:<-> (int 1)))))
                       (postfix:<()> (identifier "fib") (arglist (infix:<+> (identifier "n") (prefix:<-> (int 2))))))))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "fib") (arglist (int 2))))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "fib") (arglist (int 3))))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "fib") (arglist (int 4)))))))
        .

    is-result $ast, "2\n3\n5\n", "recursive calls with returns work out fine";
}

done-testing;
