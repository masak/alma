use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (for (array (int 1) (int 2)) (block (parameters (ident "i")) (statements
            (stexpr (call (ident "say") (ident "i")))))))
        .

    is-result $ast, "1\n2\n", "for-loops iterate over an array";
}

done;
