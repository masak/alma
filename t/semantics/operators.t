use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (compunit
          (stexpr (call (ident "say") (+ (int 38) (int 4)))))
        .

    is-result $ast, "42\n", "numeric addition works";
}

{
    my $ast = q:to/./;
        (compunit
          (stexpr (call (ident "say") (~ (str "Jame") (str "s Bond")))))
        .

    is-result $ast, "James Bond\n", "string concatenation works";
}

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "ns") (assign (ident "ns") (array (str "Jim") (str "Bond"))))
          (stexpr (call (ident "say") (index (ident "ns") (int 1)))))
        .

    is-result $ast, "Bond\n", "array indexing works";
}

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "x") (assign (ident "x") (int 1)))
          (stexpr (assign (ident "x") (int 2)))
          (stexpr (call (ident "say") (ident "x"))))
        .

    is-result $ast, "2\n", "assignment works";
}

done;
