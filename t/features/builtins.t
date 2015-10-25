use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "abs") (arglist (- (int 1)))))))
          (stexpr (call (ident "say") (arglist (call (ident "abs") (arglist (int 1)))))))
        .

    is-result $ast, "1\n1\n", "abs() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "min") (arglist (- (int 1)) (int 2))))))
          (stexpr (call (ident "say") (arglist (call (ident "min") (arglist (int 2) (- (int 1))))))))
        .

    is-result $ast, "-1\n-1\n", "min() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "max") (arglist (- (int 1)) (int 2))))))
          (stexpr (call (ident "say") (arglist (call (ident "max") (arglist (int 2) (- (int 1))))))))
        .

    is-result $ast, "2\n2\n", "max() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "chr") (arglist (int 97)))))))
        .

    is-result $ast, "a\n", "chr() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "ord") (arglist (str "a")))))))
        .

    is-result $ast, "97\n", "ord() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (call (ident "int") (arglist (str "6"))))))))
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (call (ident "int") (arglist (str "-6")))))))))
        .

    is-result $ast, "Int\nInt\n", "int() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (call (ident "str") (arglist (int 6)))))))))
        .

    is-result $ast, "Str\n", "str() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "chars") (arglist (str "007")))))))
        .

    is-result $ast, "3\n", "chars() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "uc") (arglist (str "test")))))))
        .

    is-result $ast, "TEST\n", "uc() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "lc") (arglist (str "TEST")))))))
        .

    is-result $ast, "test\n", "lc() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "trim") (arglist (str "  test  ")))))))
        .

    is-result $ast, "test\n", "trim() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "elems") (arglist (array (int 1) (int 2))))))))
        .

    is-result $ast, "2\n", "elems() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "reversed") (arglist (array (int 1) (int 2))))))))
        .

    is-result $ast, "[2, 1]\n", "reversed() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "sorted") (arglist (array (int 2) (int 1))))))))
        .

    is-result $ast, "[1, 2]\n", "sorted() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "join") (arglist (array (int 1) (int 2)) (str "|")))))))
        .

    is-result $ast, "1|2\n", "join() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "split") (arglist (str "a|b") (str "|")))))))
        .

    is-result $ast, qq|["a", "b"]\n|, "split() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "index") (arglist (str "abc") (str "bc"))))))
          (stexpr (call (ident "say") (arglist (call (ident "index") (arglist (str "abc") (str "a"))))))
          (stexpr (call (ident "say") (arglist (call (ident "index") (arglist (str "abc") (str "d")))))))
        .

    is-result $ast, "1\n0\n-1\n", "index() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "substr") (arglist (str "abc") (int 0) (int 1))))))
          (stexpr (call (ident "say") (arglist (call (ident "substr") (arglist (str "abc") (int 1))))))
          (stexpr (call (ident "say") (arglist (call (ident "substr") (arglist (str "abc") (int 0) (int 5)))))))
        .

    is-result $ast, "a\nbc\nabc\n", "substr() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "charat") (arglist (str "abc") (int 0)))))))
        .

    is-result $ast, "a\n", "charat() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "charat") (arglist (str "abc") (int 3)))))))
        .

    is-error $ast, X::Subscript::TooLarge, "charat() dies";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist (ident "n")) (stmtlist
              (return (== (ident "n") (int 2))))))
          (stexpr (call (ident "say") (arglist (call (ident "filter") (arglist (ident "f") (array (int 1) (int 2) (int 3) (int 2))))))))
        .

    is-result $ast, "[2, 2]\n", "filter() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist (ident "n")) (stmtlist
              (return (+ (ident "n") (int 1))))))
          (my (ident "a") (array (int 1) (int 2) (int 3)))
          (stexpr (call (ident "say") (arglist (call (ident "map") (arglist (ident "f") (ident "a"))))))
          (stexpr (call (ident "say") (arglist (ident "a")))))
        .

    is-result $ast, "[2, 3, 4]\n[1, 2, 3]\n", "map() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "n"))
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (ident "n")))))))
        .

    is-result $ast, "None\n", "none type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "n") (int 7))
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (ident "n")))))))
        .

    is-result $ast, "Int\n", "int type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "s") (str "Bond"))
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (ident "s")))))))
        .

    is-result $ast, "Str\n", "str type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "a") (array (int 1) (int 2)))
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (ident "a")))))))
        .

    is-result $ast, "Array\n", "array type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist)))
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (ident "f")))))))
        .

    is-result $ast, "Sub\n", "sub type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (call (ident "say") (arglist (call (ident "type") (arglist (ident "say")))))))
        .

    is-result $ast, "Sub\n", "builtin sub type() returns the same as ordinary sub";
}

done-testing;
