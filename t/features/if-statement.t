use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (my (identifier "u"))
          (if (identifier "u") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "falsy none")))))))
          (if (int 0) (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "falsy int")))))))
          (if (int 7) (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "truthy int")))))))
          (if (str "") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "falsy str")))))))
          (if (str "James") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "truthy str")))))))
          (if (array) (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "falsy array")))))))
          (if (array (str "")) (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "truthy array")))))))
          (sub (identifier "foo") (block (paramlist) (stmtlist)))
          (if (identifier "foo") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "truthy sub")))))))
          (macro (identifier "bar") (block (paramlist) (stmtlist)))
          (if (identifier "bar") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "truthy macro")))))))
          (if (object (identifier "Object") (proplist)) (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "falsy object")))))))
          (if (object (identifier "Object") (proplist (property "a" (int 3)))) (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "truthy object"))))))))
        .

    is-result $ast,
        <int str array sub macro object>.map({"truthy $_\n"}).join,
        "if statements run truthy things";
}

{
    my $ast = q:to/./;
        (stmtlist
          (if (int 7) (block (paramlist (param (identifier "a"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "a"))))))))
        .

    is-result $ast, "7\n", "if statements with parameters work as they should";
}


{
    my $ast = q:to/./;
        (stmtlist
         (if (int 1)
           (block (paramlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (arglist (str "if"))))))
           (block (paramlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (arglist (str "else"))))))))
        .
    is-result $ast, "if\n", "if-else statements run if-clause";
}

{
    my $ast = q:to/./;
        (stmtlist
         (if (int 0)
           (block (paramlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (arglist (str "if"))))))
           (block (paramlist)
             (stmtlist
              (stexpr (postfix:<()> (identifier "say") (arglist (str "else"))))))))
        .

    is-result $ast, "else\n", "if-else statements run else-clause";
}

{
    my $ast = q:to/./;
        (stmtlist
         (if (int 0)
             (block (paramlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (arglist (str "if"))))))
           (if (int 0)
               (block (paramlist)
                 (stmtlist
                  (stexpr (postfix:<()> (identifier "say") (arglist (str "else-if"))))))
             (block (paramlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (arglist (str "else")))))))))
        .

    is-result $ast, "else\n", "if-else-if-else statements run else-clause";
}

{
    my $ast = q:to/./;
        (stmtlist
         (if (int 0)
             (block (paramlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (arglist (str "if"))))))
           (if (int 1)
               (block (paramlist)
                 (stmtlist
                  (stexpr (postfix:<()> (identifier "say") (arglist (str "else-if"))))))
             (block (paramlist)
               (stmtlist
                (stexpr (postfix:<()> (identifier "say") (arglist (str "else")))))))))
        .

    is-result $ast, "else-if\n", "if-else-if-else statements run else-if-clause";
}


done-testing;
