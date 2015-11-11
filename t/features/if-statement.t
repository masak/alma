use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "u"))
          (if (ident "u") (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "falsy none")))))))
          (if (int 0) (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "falsy int")))))))
          (if (int 7) (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "truthy int")))))))
          (if (str "") (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "falsy str")))))))
          (if (str "James") (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "truthy str")))))))
          (if (array) (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "falsy array")))))))
          (if (array (str "")) (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "truthy array")))))))
          (sub (ident "foo") (block (paramlist) (stmtlist)))
          (if (ident "foo") (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "truthy sub")))))))
          (macro (ident "bar") (block (paramlist) (stmtlist)))
          (if (ident "bar") (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "truthy macro")))))))
          (if (object) (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "falsy object")))))))
          (if (object (property "a" (int 3))) (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (str "truthy object"))))))))
        .

    is-result $ast,
        <int str array sub macro object>.map({"truthy $_\n"}).join,
        "if statements run truthy things";
}

{
    my $ast = q:to/./;
        (stmtlist
          (if (int 7) (block (paramlist (ident "a")) (stmtlist
            (stexpr (call (ident "say") (arglist (ident "a"))))))))
        .

    is-result $ast, "7\n", "if statements with parameters work as they should";
}

done-testing;
