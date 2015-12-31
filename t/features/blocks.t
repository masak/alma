use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stblock (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "OH HAI from inside block"))))))))
        .

    is-result $ast, "OH HAI from inside block\n", "immediate blocks work";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "x") (str "one"))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "x"))))
          (stblock (block (parameterlist) (statementlist
            (my (identifier "x") (str "two"))
            (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "x")))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "blocks have their own variable scope";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "b") (block (parameterlist (param (identifier "name"))) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<~> (str "Good evening, Mr ") (identifier "name"))))))))
          (stexpr (postfix:<()> (identifier "b") (argumentlist (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a block with parameters works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "b") (block (parameterlist (param (identifier "X")) (param (identifier "Y"))) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<~> (identifier "X") (identifier "Y"))))))))
          (my (identifier "X") (str "y"))
          (stexpr (postfix:<()> (identifier "b") (argumentlist (str "X") (infix:<~> (identifier "X") (identifier "X"))))))
        .

    is-result $ast, "Xyy\n", "arguments are evaluated before parameters are bound";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "b") (block (parameterlist (param (identifier "callback"))) (statementlist
            (my (identifier "scoping") (str "dynamic"))
            (stexpr (postfix:<()> (identifier "callback") (argumentlist))))))
          (my (identifier "scoping") (str "lexical"))
          (stexpr (postfix:<()> (identifier "b") (argumentlist (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "scoping"))))))))))
        .

    is-result $ast, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "b") (block (parameterlist (param (identifier "count"))) (statementlist
            (if (identifier "count") (block (parameterlist) (statementlist
              (stexpr (postfix:<()> (identifier "b") (argumentlist (infix:<+> (identifier "count") (prefix:<-> (int 1))))))
              (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "count"))))))))))
          (stexpr (postfix:<()> (identifier "b") (argumentlist (int 4)))))
        .

    is-result $ast, "1\n2\n3\n4\n", "each block invocation gets its own callframe/scope";
}

done-testing;
