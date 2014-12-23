use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (sub (ident "fib") (parameters (ident "n")) (statements
            (if (== (ident n) (int 0)) (block (parameters) (statements
              (return (int 1)))))
            (if (== (ident n) (int 1)) (block (parameters) (statements
              (return (int 1)))))
            (return (+ (call (ident "fib") (arguments (+ (ident "n") (- (int 1)))))
                       (call (ident "fib") (arguments (+ (ident "n") (- (int 2)))))))))
          (stexpr (call (ident "say") (arguments (call (ident "fib") (arguments (int 2))))))
          (stexpr (call (ident "say") (arguments (call (ident "fib") (arguments (int 3))))))
          (stexpr (call (ident "say") (arguments (call (ident "fib") (arguments (int 4)))))))
        .

    is-result $ast, "2\n3\n5\n", "recursive calls with returns work out fine";
}

done;
