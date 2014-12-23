use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (vardecl (ident "n"))
          (stexpr (call (ident "say") (arguments (call (ident "typeof") (arguments (ident "n")))))))
        .

    is-result $ast, "None\n", "none typeof() works";
}

{
    my $ast = q:to/./;
        (statements
          (vardecl (ident "n") (assign (ident "n") (int 7)))
          (stexpr (call (ident "say") (arguments (call (ident "typeof") (arguments (ident "n")))))))
        .

    is-result $ast, "Int\n", "int typeof() works";
}

{
    my $ast = q:to/./;
        (statements
          (vardecl (ident "s") (assign (ident "s") (str "Bond")))
          (stexpr (call (ident "say") (arguments (call (ident "typeof") (arguments (ident "s")))))))
        .

    is-result $ast, "Str\n", "str typeof() works";
}

{
    my $ast = q:to/./;
        (statements
          (vardecl (ident "a") (assign (ident "a") (array (int 1) (int 2))))
          (stexpr (call (ident "say") (arguments (call (ident "typeof") (arguments (ident "a")))))))
        .

    is-result $ast, "Array\n", "array typeof() works";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements))
          (stexpr (call (ident "say") (arguments (call (ident "typeof") (arguments (ident "f")))))))
        .

    is-result $ast, "Sub\n", "sub typeof() works";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (call (ident "typeof") (arguments (ident "say")))))))
        .

    is-result $ast, "Sub\n", "builtin sub typeof() works";
}

done;
