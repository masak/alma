use v6;
use Test;
use _007::Test;
{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "abs") (arguments (- (int 1)))))))
          (stexpr (call (ident "say") (arguments (call (ident "abs") (arguments (int 1)))))))
        .

    is-result $ast, "1\n1\n", "abs() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "min") (arguments (- (int 1)) (int 2))))))
          (stexpr (call (ident "say") (arguments (call (ident "min") (arguments (int 2) (- (int 1))))))))
        .

    is-result $ast, "-1\n-1\n", "min() works";
}

done;
