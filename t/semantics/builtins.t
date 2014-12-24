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

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "max") (arguments (- (int 1)) (int 2))))))
          (stexpr (call (ident "say") (arguments (call (ident "max") (arguments (int 2) (- (int 1))))))))
        .

    is-result $ast, "2\n2\n", "max() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "chr") (arguments (int 97)))))))
        .

    is-result $ast, "a\n", "chr() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "ord") (arguments (str "a")))))))
        .

    is-result $ast, "97\n", "ord() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (call (ident "int") (arguments (str "6"))))))))
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (call (ident "int") (arguments (str "-6")))))))))
        .

    is-result $ast, "Int\nInt\n", "int() works";
}

done;
