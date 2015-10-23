use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "u") (int 3))
          (while (ident "u") (block (paramlist) (stmtlist
            (stexpr (call (ident "say") (arglist (ident "u"))))
            (stexpr (assign (ident "u") (+ (ident "u") (- (int 1)))))))))
        .

    is-result $ast, "3\n2\n1\n", "while loops stops when the condition is false";
}

done-testing;
