use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (my (identifier "u"))
          (if (identifier "u") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "falsy none")))))))
          (if (int 0) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "falsy int")))))))
          (if (int 7) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "truthy int")))))))
          (if (str "") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "falsy str")))))))
          (if (str "James") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "truthy str")))))))
          (if (array) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "falsy array")))))))
          (if (array (str "")) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "truthy array")))))))
          (sub (identifier "foo") (block (parameterlist) (stmtlist)))
          (if (identifier "foo") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "truthy sub")))))))
          (macro (identifier "bar") (block (parameterlist) (stmtlist)))
          (if (identifier "bar") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "truthy macro")))))))
          (if (object (identifier "Object") (proplist)) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "falsy object")))))))
          (if (object (identifier "Object") (proplist (property "a" (int 3)))) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "truthy object"))))))))
        .

    is-result $ast,
        <int str array sub macro object>.map({"truthy $_\n"}).join,
        "if statements run truthy things";
}

{
    my $ast = q:to/./;
        (stmtlist
          (if (int 7) (block (parameterlist (param (identifier "a"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a"))))))))
        .

    is-result $ast, "7\n", "if statements with parameters work as they should";
}


{
    my $ast = q:to/./;
        (stmtlist
         (if (int 1)
           (block (parameterlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (argumentlist (str "if"))))))
           (block (parameterlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (argumentlist (str "else"))))))))
        .
    is-result $ast, "if\n", "if-else statements run if-clause";
}

{
    my $ast = q:to/./;
        (stmtlist
         (if (int 0)
           (block (parameterlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (argumentlist (str "if"))))))
           (block (parameterlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (argumentlist (str "else"))))))))
        .

    is-result $ast, "else\n", "if-else statements run else-clause";
}

{
    my $ast = q:to/./;
        (stmtlist
         (if (int 0)
             (block (parameterlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (argumentlist (str "if"))))))
           (if (int 0)
               (block (parameterlist)
                 (stmtlist
                  (stexpr (postfix:<()> (identifier "say") (argumentlist (str "else-if"))))))
             (block (parameterlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (argumentlist (str "else")))))))))
        .

    is-result $ast, "else\n", "if-else-if-else statements run else-clause";
}

{
    my $ast = q:to/./;
        (stmtlist
         (if (int 0)
             (block (parameterlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (argumentlist (str "if"))))))
           (if (int 1)
               (block (parameterlist)
                 (stmtlist
                  (stexpr (postfix:<()> (identifier "say") (argumentlist (str "else-if"))))))
             (block (parameterlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (argumentlist (str "else")))))))))
        .

    is-result $ast, "else-if\n", "if-else-if-else statements run else-if-clause";
}


done-testing;
