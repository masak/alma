use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "n") (assign (ident "n") (int 7)))
          (stexpr (call (ident "say") (ident "n"))))
        .

    is-result $ast, "7\n", "int type works";
}

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "s") (assign (ident "s") (str "Bond")))
          (stexpr (call (ident "say") (ident "s"))))
        .

    is-result $ast, "Bond\n", "str type works";
}

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "n") (assign (ident "n") (array (int 1) (int 2))))
          (stexpr (call (ident "say") (ident "n"))))
        .

    is-result $ast, "[1, 2]\n", "array type works";
}

done;
