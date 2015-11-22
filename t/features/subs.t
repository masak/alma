use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (str "OH HAI from inside sub"))))))))
        .

    is-result $ast, "", "subs are not immediate";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "x") (str "one"))
          (stexpr (postfix:<()> (ident "say") (arglist (ident "x"))))
          (sub (ident "f") (block (paramlist) (stmtlist
            (my (ident "x") (str "two"))
            (stexpr (postfix:<()> (ident "say") (arglist (ident "x")))))))
          (stexpr (postfix:<()> (ident "f") (arglist)))
          (stexpr (postfix:<()> (ident "say") (arglist (ident "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "subs have their own variable scope";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist (ident "name")) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (infix:<~> (str "Good evening, Mr ") (ident "name"))))))))
          (stexpr (postfix:<()> (ident "f") (arglist (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a sub with parameters works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist (ident "X") (ident "Y")) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (infix:<~> (ident "X") (ident "Y"))))))))
          (my (ident "X") (str "y"))
          (stexpr (postfix:<()> (ident "f") (arglist (str "X") (infix:<~> (ident "X") (ident "X"))))))
        .

    is-result $ast, "Xyy\n", "arglist are evaluated before parameters are bound";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist (ident "callback")) (stmtlist
            (my (ident "scoping") (str "dynamic"))
            (stexpr (postfix:<()> (ident "callback") (arglist))))))
          (my (ident "scoping") (str "lexical"))
          (stexpr (postfix:<()> (ident "f") (arglist (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (ident "scoping"))))))))))
        .

    is-result $ast, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "f") (arglist)))
          (sub (ident "f") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (str "OH HAI from inside sub"))))))))
        .

    is-result $ast, "OH HAI from inside sub\n", "call a sub before declaring it";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "f") (arglist)))
          (my (ident "x") (str "X"))
          (sub (ident "f") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (ident "x"))))))))
        .

    is-result $ast, "None\n", "using an outer lexical in a sub that's called before the outer lexical's declaration";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (str "OH HAI")))))))
          (sub (ident "g") (block (paramlist) (stmtlist
            (return (block (paramlist) (stmtlist
              (stexpr (postfix:<()> (ident "f") (arglist)))))))))
          (stexpr (postfix:<()> (postfix:<()> (ident "g") (arglist)) (arglist))))
        .

    is-result $ast, "OH HAI\n", "left hand of a call doesn't have to be an identifier, just has to resolve to a callable";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "f") (arglist (str "Bond"))))
          (sub (ident "f") (block (paramlist (ident "name")) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (infix:<~> (str "Good evening, Mr ") (ident "name")))))))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a post-declared sub works (I)";
}

{
    my $program = 'f("Bond"); sub f(name) { say("Good evening, Mr " ~ name) }';

    outputs $program, "Good evening, Mr Bond\n", "calling a post-declared sub works (II)";
}

done-testing;
