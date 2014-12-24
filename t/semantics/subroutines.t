use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "OH HAI from inside sub")))))))
        .

    is-result $ast, "", "subs are not immediate";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "x") (assign (ident "x") (str "one")))
          (stexpr (call (ident "say") (arguments (ident "x"))))
          (sub (ident "f") (parameters) (statements
            (my (ident "x") (assign (ident "x") (str "two")))
            (stexpr (call (ident "say") (arguments (ident "x"))))))
          (stexpr (call (ident "f") (arguments)))
          (stexpr (call (ident "say") (arguments (ident "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "subs have their own variable scope";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters (ident "name")) (statements
            (stexpr (call (ident "say") (arguments (~ (str "Good evening, Mr ") (ident "name")))))))
          (stexpr (call (ident "f") (arguments (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a sub with parameters works";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters (ident "X") (ident "Y")) (statements
            (stexpr (call (ident "say") (arguments (~ (ident "X") (ident "Y")))))))
          (my (ident "X") (assign (ident "X") (str "y")))
          (stexpr (call (ident "f") (arguments (str "X") (~ (ident "X") (ident "X"))))))
        .

    is-result $ast, "Xyy\n", "arguments are evaluated before parameters are bound";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters (ident "callback")) (statements
            (my (ident "scoping") (assign (ident "scoping") (str "dynamic")))
            (stexpr (call (ident "callback") (arguments)))))
          (my (ident "scoping") (assign (ident "scoping") (str "lexical")))
          (stexpr (call (ident "f") (arguments (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (ident "scoping"))))))))))
        .

    is-result $ast, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "f") (arguments)))
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "OH HAI from inside sub")))))))
        .

    is-result $ast, "OH HAI from inside sub\n", "call a sub before declaring it";
}

{
    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "f") (arguments)))
          (my (ident "x") (str "X"))
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (ident "x")))))))
        .

    is-result $ast, "None\n", "using an outer lexical in a sub that's called before the outer lexical's declaration";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "OH HAI"))))))
          (sub (ident "g") (parameters) (statements
            (return (block (parameters) (statements
              (stexpr (call (ident "f") (arguments))))))))
          (stexpr (call (call (ident "g") (arguments)) (arguments))))
        .

    is-result $ast, "OH HAI\n", "left hand of a call doesn't have to be an identifier, just has to resolve to a callable";
}

done;
