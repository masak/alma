use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (my (ident "n"))
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (ident "n")))))))
        .

    is-result $ast, "None\n", "none type() works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "n") (assign (ident "n") (int 7)))
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (ident "n")))))))
        .

    is-result $ast, "Int\n", "int type() works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "s") (assign (ident "s") (str "Bond")))
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (ident "s")))))))
        .

    is-result $ast, "Str\n", "str type() works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "a") (assign (ident "a") (array (int 1) (int 2))))
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (ident "a")))))))
        .

    is-result $ast, "Array\n", "array type() works";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements))
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (ident "f")))))))
        .

    is-result $ast, "Sub\n", "sub type() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "type") (arguments (ident "say")))))))
        .

    is-result $ast, "Sub\n", "builtin sub type() returns the same as ordinary sub";
}

done;
