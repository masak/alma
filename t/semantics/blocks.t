use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (stblock (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "OH HAI from inside block"))))))))
        .

    is-result $ast, "OH HAI from inside block\n", "immediate blocks work";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "x") (assign (ident "x") (str "one")))
          (stexpr (call (ident "say") (arguments (ident "x"))))
          (stblock (block (parameters) (statements
            (my (ident "x") (assign (ident "x") (str "two")))
            (stexpr (call (ident "say") (arguments (ident "x")))))))
          (stexpr (call (ident "say") (arguments (ident "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "blocks have their own variable scope";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "b") (assign (ident "b") (block (parameters (ident "name")) (statements
            (stexpr (call (ident "say") (arguments (~ (str "Good evening, Mr ") (ident "name")))))))))
          (stexpr (call (ident "b") (arguments (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a block with parameters works";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "b") (assign (ident "b") (block (parameters (ident "X") (ident "Y")) (statements
            (stexpr (call (ident "say") (arguments (~ (ident "X") (ident "Y")))))))))
          (my (ident "X") (assign (ident "X") (str "y")))
          (stexpr (call (ident "b") (arguments (str "X") (~ (ident "X") (ident "X"))))))
        .

    is-result $ast, "Xyy\n", "arguments are evaluated before parameters are bound";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "b") (assign (ident "b") (block (parameters (ident "callback")) (statements
            (my (ident "scoping") (assign (ident "scoping") (str "dynamic")))
            (stexpr (call (ident "callback") (arguments)))))))
          (my (ident "scoping") (assign (ident "scoping") (str "lexical")))
          (stexpr (call (ident "b") (arguments (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (ident "scoping"))))))))))
        .

    is-result $ast, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (statements
          (my (ident "b") (assign (ident "b") (block (parameters (ident "count")) (statements
            (if (ident "count") (block (parameters) (statements
              (stexpr (call (ident "b") (arguments (+ (ident "count") (- (int 1))))))
              (stexpr (call (ident "say") (arguments (ident "count")))))))))))
          (stexpr (call (ident "b") (arguments (int 4)))))
        .

    is-result $ast, "1\n2\n3\n4\n", "each block invocation gets its own callframe/scope";
}

done;
