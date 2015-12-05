use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "fib") (block (paramlist (param (ident "n"))) (stmtlist
            (if (infix:<==> (ident "n") (int 0)) (block (paramlist) (stmtlist
              (return (int 1)))))
            (if (infix:<==> (ident "n") (int 1)) (block (paramlist) (stmtlist
              (return (int 1)))))
            (return (infix:<+> (postfix:<()> (ident "fib") (arglist (infix:<+> (ident "n") (prefix:<-> (int 1)))))
                       (postfix:<()> (ident "fib") (arglist (infix:<+> (ident "n") (prefix:<-> (int 2))))))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "fib") (arglist (int 2))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "fib") (arglist (int 3))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "fib") (arglist (int 4)))))))
        .

    is-result $ast, "2\n3\n5\n", "recursive calls with returns work out fine";
}

done-testing;
