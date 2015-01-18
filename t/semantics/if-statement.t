use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (my (ident "u"))
          (if (ident "u") (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "falsy none")))))))
          (if (int 0) (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "falsy int")))))))
          (if (int 7) (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "truthy int")))))))
          (if (str "") (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "falsy str")))))))
          (if (str "James") (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "truthy str")))))))
          (if (array) (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "falsy array")))))))
          (if (array (str "")) (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "truthy array"))))))))
        .

    is-result $ast, "truthy int\ntruthy str\ntruthy array\n", "if statements run truthy things";
}

{
    my $ast = q:to/./;
        (statements
          (if (int 7) (block (parameters (ident "a")) (statements
            (stexpr (call (ident "say") (arguments (ident "a"))))))))
        .

    is-result $ast, "7\n", "if statements with parameters work as they should";
}

done;
