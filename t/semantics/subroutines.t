use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (compunit
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (str "OH HAI from inside sub"))))))
        .

    is-result $ast, "", "immediate subs doesn't work";
}

{
    my $ast = q:to/./;
        (compunit
          (vardecl (ident "x") (assign (ident "x") (str "one")))
          (stexpr (call (ident "say") (ident "x")))
          (sub (ident "f") (parameters) (statements
            (vardecl (ident "x") (assign (ident "x") (str "two")))
            (stexpr (call (ident "say") (ident "x")))))
          (stexpr (call (ident "f")))
          (stexpr (call (ident "say") (ident "x"))))
        .

    is-result $ast, "one\ntwo\none\n", "subs have their own variable scope";
}

{
    my $ast = q:to/./;
        (compunit
          (sub (ident "f") (parameters (ident "name")) (statements
            (stexpr (call (ident "say") (~ (str "Good evening, Mr ") (ident "name"))))))
          (stexpr (call (ident "f") (str "Bond"))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a sub with parameters works";
}

{
    my $ast = q:to/./;
        (compunit
          (sub (ident "f") (parameters (ident "X") (ident "Y")) (statements
            (stexpr (call (ident "say") (~ (ident "X") (ident "Y"))))))
          (vardecl (ident "X") (assign (ident "X") (str "y")))
          (stexpr (call (ident "f") (str "X") (~ (ident "X") (ident "X")))))
        .

    is-result $ast, "Xyy\n", "arguments are evaluated before parameters are bound";
}

{
    my $ast = q:to/./;
        (compunit
          (sub (ident "f") (parameters (ident "callback")) (statements
            (vardecl (ident "scoping") (assign (ident "scoping") (str "dynamic")))
            (stexpr (call (ident "callback")))))
          (vardecl (ident "scoping") (assign (ident "scoping") (str "lexical")))
          (stexpr (call (ident "f") (block (parameters) (statements
            (stexpr (call (ident "say") (ident "scoping"))))))))
        .

    is-result $ast, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (compunit
          (stexpr (call (ident "f")))
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (str "OH HAI from inside sub"))))))
        .

    is-result $ast, "OH HAI from inside sub\n", "call a sub before declaring it";
}

{
    my $ast = q:to/./;
        (compunit
          (stexpr (call (ident "f")))
          (vardecl (ident "x") (str "X"))
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (ident "x"))))))
        .

    is-result $ast, "X\n", "using an outer lexical in a sub that's called before the outer lexical's declaration";
}

done;
