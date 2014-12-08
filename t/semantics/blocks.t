use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (compunit
          (stblock (block (parameters) (statements
            (stexpr (call (ident "say") (str "OH HAI from inside block")))))))
        .

    is-result $ast, "OH HAI from inside block\n", "immediate blocks work";
}

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "x") (assign (ident "x") (str "one")))
          (stexpr (call (ident "say") (ident "x")))
          (stblock (block (parameters) (statements
            (vardecl (ident "x") (assign (ident "x") (str "two")))
            (stexpr (call (ident "say") (ident "x"))))))
          (stexpr (call (ident "say") (ident "x"))))
        .

    is-result $ast, "one\ntwo\none\n", "blocks have their own variable scope";
}

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "b") (assign (ident "b") (block (parameters (ident "name")) (statements
            (stexpr (call (ident "say") (~ (str "Good evening, Mr ") (ident "name"))))))))
          (stexpr (call (ident "b") (str "Bond"))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a block with parameters works";
}

done;
