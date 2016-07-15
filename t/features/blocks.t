use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stblock (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "OH HAI from inside block"))))))))
        .

    is-result $ast, "OH HAI from inside block\n", "immediate blocks work";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "x") (str "one"))
          (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x"))))
          (stblock (block (parameterlist) (statementlist
            (my (identifier "x") (str "two"))
            (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x")))))))
          (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "blocks have their own variable scope";
}

done-testing;
