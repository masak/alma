use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (stblock (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "OH HAI from inside block"))))))))
        .

    is-result $ast, "OH HAI from inside block\n", "immediate blocks work";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "x") (str "one"))
          (stexpr (call (ident "say") (arglist (ident "x"))))
          (stblock (block (paramlist) (stmtlist
            (my (ident "x") (str "two"))
            (stexpr (call (ident "say") (arglist (ident "x")))))))
          (stexpr (call (ident "say") (arglist (ident "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "blocks have their own variable scope";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "name")) (stmtlist
            (stexpr (call (ident "say") (arglist (~ (str "Good evening, Mr ") (ident "name"))))))))
          (stexpr (call (ident "b") (arglist (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a block with parameters works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "X") (ident "Y")) (stmtlist
            (stexpr (call (ident "say") (arglist (~ (ident "X") (ident "Y"))))))))
          (my (ident "X") (str "y"))
          (stexpr (call (ident "b") (arglist (str "X") (~ (ident "X") (ident "X"))))))
        .

    is-result $ast, "Xyy\n", "arguments are evaluated before parameters are bound";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "callback")) (stmtlist
            (my (ident "scoping") (str "dynamic"))
            (stexpr (call (ident "callback") (arglist))))))
          (my (ident "scoping") (str "lexical"))
          (stexpr (call (ident "b") (arglist (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (ident "scoping"))))))))))
        .

    is-result $ast, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "count")) (stmtlist
            (if (ident "count") (block (paramlist) (stmtlist
              (stexpr (call (ident "b") (arglist (+ (ident "count") (- (int 1))))))
              (stexpr (call (ident "say") (arglist (ident "count"))))))))))
          (stexpr (call (ident "b") (arglist (int 4)))))
        .

    is-result $ast, "1\n2\n3\n4\n", "each block invocation gets its own callframe/scope";
}

done-testing;
