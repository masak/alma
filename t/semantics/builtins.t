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

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (call (ident "str") (arguments (int 6)))))))))
        .

    is-result $ast, "Str\n", "str() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "chars") (arguments (str "007")))))))
        .

    is-result $ast, "3\n", "chars() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "uc") (arguments (str "test")))))))
        .

    is-result $ast, "TEST\n", "uc() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "lc") (arguments (str "TEST")))))))
        .

    is-result $ast, "test\n", "lc() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "trim") (arguments (str "  test  ")))))))
        .

    is-result $ast, "test\n", "trim() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "elems") (arguments (array (int 1) (int 2))))))))
        .

    is-result $ast, "2\n", "elems() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "reversed") (arguments (array (int 1) (int 2))))))))
        .

    is-result $ast, "[2, 1]\n", "reversed() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "sorted") (arguments (array (int 2) (int 1))))))))
        .

    is-result $ast, "[1, 2]\n", "sorted() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "join") (arguments (array (int 1) (int 2)) (str "|")))))))
        .

    is-result $ast, "1|2\n", "join() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "split") (arguments (str "a|b") (str "|")))))))
        .

    is-result $ast, "[a, b]\n", "split() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "index") (arguments (str "abc") (str "bc"))))))
          (stexpr (call (ident "say") (arguments (call (ident "index") (arguments (str "abc") (str "a"))))))
          (stexpr (call (ident "say") (arguments (call (ident "index") (arguments (str "abc") (str "d")))))))
        .

    is-result $ast, "1\n0\n-1\n", "index() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "substr") (arguments (str "abc") (int 0) (int 1))))))
          (stexpr (call (ident "say") (arguments (call (ident "substr") (arguments (str "abc") (int 1))))))
          (stexpr (call (ident "say") (arguments (call (ident "substr") (arguments (str "abc") (int 0) (int 5)))))))
        .

    is-result $ast, "a\nbc\nabc\n", "substr() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "charat") (arguments (str "abc") (int 0)))))))
        .

    is-result $ast, "a\n", "charat() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "charat") (arguments (str "abc") (int 3)))))))
        .

    is-error $ast, X::Subscript::TooLarge, "charat() dies";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters (ident "n")) (statements
              (return (== (ident "n") (int 2)))))
          (stexpr (call (ident "say") (arguments (call (ident "grep") (arguments (ident "f") (array (int 1) (int 2) (int 3) (int 2))))))))
        .

    is-result $ast, "[2, 2]\n", "grep() works";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters (ident "n")) (statements
              (return (+ (ident "n") (int 1)))))
          (my (ident "a") (assign (ident "a") (array (int 1) (int 2) (int 3))))
          (stexpr (call (ident "say") (arguments (call (ident "map") (arguments (ident "f") (ident "a"))))))
          (stexpr (call (ident "say") (arguments (ident "a")))))
        .

    is-result $ast, "[2, 3, 4]\n[1, 2, 3]\n", "map() works";
}

done;
