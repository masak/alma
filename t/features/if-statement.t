use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "u"))
          (if (identifier "u") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "falsy none")))))))
          (if (int 0) (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "falsy int")))))))
          (if (int 7) (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "truthy int")))))))
          (if (str "") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "falsy str")))))))
          (if (str "James") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "truthy str")))))))
          (if (array) (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "falsy array")))))))
          (if (array (str "")) (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "truthy array")))))))
          (stsub (identifier "foo") (block (parameterlist) (statementlist)))
          (if (identifier "foo") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "truthy sub")))))))
          (macro (identifier "bar") (block (parameterlist) (statementlist)))
          (if (identifier "bar") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "truthy macro")))))))
          (if (object (identifier "Object") (propertylist)) (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "falsy object")))))))
          (if (object (identifier "Object") (propertylist (property "a" (int 3)))) (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "truthy object")))))))
          (if (object (identifier "Q::Literal::Int") (propertylist (property "value" (int 0))))
            (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "truthy qnode"))))))))
        .

    is-result $ast,
        <int str array sub macro object qnode>.map({"truthy $_\n"}).join,
        "if statements run truthy things";
}

{
    my $ast = q:to/./;
        (statementlist
          (if (int 7) (block (parameterlist (param (identifier "a"))) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (identifier "a"))))))))
        .

    is-result $ast, "7\n", "if statements with parameters work as they should (#2)";
}


{
    my $ast = q:to/./;
        (statementlist
         (if (int 1)
           (block (parameterlist)
             (statementlist
              (stexpr (postfix:() (identifier "say") (argumentlist (str "if"))))))
           (block (parameterlist)
             (statementlist
              (stexpr (postfix:() (identifier "say") (argumentlist (str "else"))))))))
        .
    is-result $ast, "if\n", "if-else statements run if-clause";
}

{
    my $ast = q:to/./;
        (statementlist
         (if (int 0)
           (block (parameterlist)
             (statementlist
              (stexpr (postfix:() (identifier "say") (argumentlist (str "if"))))))
           (block (parameterlist)
             (statementlist
              (stexpr (postfix:() (identifier "say") (argumentlist (str "else"))))))))
        .

    is-result $ast, "else\n", "if-else statements run else-clause";
}

{
    my $ast = q:to/./;
        (statementlist
         (if (int 0)
             (block (parameterlist)
               (statementlist
                (stexpr (postfix:() (identifier "say") (argumentlist (str "if"))))))
           (if (int 0)
               (block (parameterlist)
                 (statementlist
                  (stexpr (postfix:() (identifier "say") (argumentlist (str "else-if"))))))
             (block (parameterlist)
               (statementlist
                (stexpr (postfix:() (identifier "say") (argumentlist (str "else")))))))))
        .

    is-result $ast, "else\n", "if-else-if-else statements run else-clause";
}

{
    my $ast = q:to/./;
        (statementlist
         (if (int 0)
             (block (parameterlist)
               (statementlist
                (stexpr (postfix:() (identifier "say") (argumentlist (str "if"))))))
           (if (int 1)
               (block (parameterlist)
                 (statementlist
                  (stexpr (postfix:() (identifier "say") (argumentlist (str "else-if"))))))
             (block (parameterlist)
               (statementlist
                (stexpr (postfix:() (identifier "say") (argumentlist (str "else")))))))))
        .

    is-result $ast, "else-if\n", "if-else-if-else statements run else-if-clause";
}

{
    my $program = q:to/./;
        if 0 {
        }
        say("no parsefail");
        .

    outputs
        $program,
        "no parsefail\n",
        "regression test -- newline after an if block is enough, no semicolon needed";
}

done-testing;
