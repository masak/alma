use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (my (ident "u") (assign (ident "u") (int 3)))
          (while (ident "u") (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (ident "u"))))
            (stexpr (assign (ident "u") (+ (ident "u") (- (int 1)))))))))
        .

    is-result $ast, "3\n2\n1\n", "while loops stops when the condition is false";
}

done;
