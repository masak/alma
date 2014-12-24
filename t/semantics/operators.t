use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (+ (int 38) (int 4))))))
        .

    is-result $ast, "42\n", "numeric addition works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (~ (str "Jame") (str "s Bond"))))))
        .

    is-result $ast, "James Bond\n", "string concatenation works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "ns") (assign (ident "ns") (array (str "Jim") (str "Bond"))))
          (stexpr (call (ident "say") (arguments (index (ident "ns") (int 1))))))
        .

    is-result $ast, "Bond\n", "array indexing works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "x") (assign (ident "x") (int 1)))
          (stexpr (assign (ident "x") (int 2)))
          (stexpr (call (ident "say") (arguments (ident "x")))))
        .

    is-result $ast, "2\n", "assignment works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "i1") (assign (ident "i1") (int 10)))
          (my (ident "i2") (assign (ident "i2") (int 11)))
          (my (ident "s1") (assign (ident "s1") (str "10")))
          (my (ident "s2") (assign (ident "s2") (str "11")))
          (my (ident "a1") (assign (ident "a1") (array (int 1) (int 2) (int 3))))
          (my (ident "a2") (assign (ident "a2") (array (int 1) (int 2) (str "3"))))

          (stexpr (call (ident "say") (arguments (== (ident "i1") (ident "i1")))))
          (stexpr (call (ident "say") (arguments (== (ident "i1") (ident "i2")))))
          (stexpr (call (ident "say") (arguments (== (ident "s1") (ident "s1")))))
          (stexpr (call (ident "say") (arguments (== (ident "s1") (ident "s2")))))
          (stexpr (call (ident "say") (arguments (== (ident "a1") (ident "a1")))))
          (stexpr (call (ident "say") (arguments (== (ident "a1") (ident "a2")))))
          (stexpr (call (ident "say") (arguments (== (ident "i1") (ident "s1")))))
          (stexpr (call (ident "say") (arguments (== (ident "s1") (ident "a1")))))
          (stexpr (call (ident "say") (arguments (== (ident "a1") (ident "i1"))))))
        .

    is-result $ast, <1 0 1 0 1 0 0 0 0>.map(* ~ "\n").join, "equality testing works";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "empty") (parameters) (statements))
          (my (ident "none") (assign (ident "none") (call (ident "empty") (arguments))))
          (stexpr (call (ident "say") (arguments (== (ident "none") (ident "none")))))
          (stexpr (call (ident "say") (arguments (== (ident "none") (int 0)))))
          (stexpr (call (ident "say") (arguments (== (ident "none") (str "")))))
          (stexpr (call (ident "say") (arguments (== (ident "none") (array))))))
        .

    is-result $ast, "1\n0\n0\n0\n", "equality testing with none matches itself but nothing else";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "ns") (assign (ident "ns") (array (str "Jim") (str "Bond"))))
          (stexpr (call (ident "say") (arguments (index (ident "ns") (- (int 2)))))))
        .

    is-error $ast, X::Subscript::Negative, "negative array indexing is an error";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "ns") (assign (ident "ns") (array (str "Jim") (str "Bond"))))
          (stexpr (call (ident "say") (arguments (index (ident "ns") (int 19))))))
        .

    is-error $ast, X::Subscript::TooLarge, "indexing beyond the last element is an error";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (+ (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "adding non-ints is an error";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (~ (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "concatenating non-strs is an error";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "ns") (assign (ident "ns") (str "Jim")))
          (stexpr (call (ident "say") (arguments (index (ident "ns") (int 0))))))
        .

    is-error $ast, X::TypeCheck, "indexing a non-array is an error";
}

done;
