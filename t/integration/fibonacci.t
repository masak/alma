use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "fib") (block (paramlist (ident "n")) (stmtlist
            (if (== (ident n) (int 0)) (block (paramlist) (stmtlist
              (return (int 1)))))
            (if (== (ident n) (int 1)) (block (paramlist) (stmtlist
              (return (int 1)))))
            (return (+ (call (ident "fib") (arglist (+ (ident "n") (- (int 1)))))
                       (call (ident "fib") (arglist (+ (ident "n") (- (int 2))))))))))
          (stexpr (call (ident "say") (arglist (call (ident "fib") (arglist (int 2))))))
          (stexpr (call (ident "say") (arglist (call (ident "fib") (arglist (int 3))))))
          (stexpr (call (ident "say") (arglist (call (ident "fib") (arglist (int 4)))))))
        .

    is-result $ast, "2\n3\n5\n", "recursive calls with returns work out fine";
}

done-testing;
