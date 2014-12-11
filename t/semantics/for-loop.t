use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (for (array (int 1) (int 2)) (block (parameters) (statements
            (stexpr (call (ident "say") (str "i")))))))
        .

    is-result $ast, "i\ni\n", "for-loops without params iterate over an array";
}

{
    my $ast = q:to/./;
        (statements
          (for (array (int 1) (int 2)) (block (parameters (ident "i")) (statements
            (stexpr (call (ident "say") (ident "i")))))))
        .

    is-result $ast, "1\n2\n", "for-loops with 1 param iterate over an array";
}

{
    my $ast = q:to/./;
        (statements
          (for (array (int 1) (int 2) (int 3) (int 4)) (block (parameters (ident "i") (ident "j")) (statements
            (stexpr (call (ident "say") (ident "i")))
            (stexpr (call (ident "say") (ident "j")))))))
        .

    is-result $ast, "1\n2\n3\n4\n", "for-loops with more params iterate over an array";
}

done;
