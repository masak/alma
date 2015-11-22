use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (stblock (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (str "OH HAI from inside block"))))))))
        .

    is-result $ast, "OH HAI from inside block\n", "immediate blocks work";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "x") (str "one"))
          (stexpr (postfix:<()> (ident "say") (arglist (ident "x"))))
          (stblock (block (paramlist) (stmtlist
            (my (ident "x") (str "two"))
            (stexpr (postfix:<()> (ident "say") (arglist (ident "x")))))))
          (stexpr (postfix:<()> (ident "say") (arglist (ident "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "blocks have their own variable scope";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "name")) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (infix:<~> (str "Good evening, Mr ") (ident "name"))))))))
          (stexpr (postfix:<()> (ident "b") (arglist (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a block with parameters works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "X") (ident "Y")) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (infix:<~> (ident "X") (ident "Y"))))))))
          (my (ident "X") (str "y"))
          (stexpr (postfix:<()> (ident "b") (arglist (str "X") (infix:<~> (ident "X") (ident "X"))))))
        .

    is-result $ast, "Xyy\n", "arguments are evaluated before parameters are bound";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "callback")) (stmtlist
            (my (ident "scoping") (str "dynamic"))
            (stexpr (postfix:<()> (ident "callback") (arglist))))))
          (my (ident "scoping") (str "lexical"))
          (stexpr (postfix:<()> (ident "b") (arglist (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (ident "scoping"))))))))))
        .

    is-result $ast, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "b") (block (paramlist (ident "count")) (stmtlist
            (if (ident "count") (block (paramlist) (stmtlist
              (stexpr (postfix:<()> (ident "b") (arglist (infix:<+> (ident "count") (prefix:<-> (int 1))))))
              (stexpr (postfix:<()> (ident "say") (arglist (ident "count"))))))))))
          (stexpr (postfix:<()> (ident "b") (arglist (int 4)))))
        .

    is-result $ast, "1\n2\n3\n4\n", "each block invocation gets its own callframe/scope";
}

done-testing;
