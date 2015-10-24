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

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "u") (int 3))
          (while (ident "u") (block (paramlist (ident "x")) (stmtlist
            (stexpr (ident "x"))
            (stexpr (assign (ident "u") (+ (ident "u") (- (int 1)))))))))
        .

    is-result $ast, "", "the block parameter is available from inside the loop";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "u") (int 3))
          (while (ident "u") (block (paramlist (ident "x")) (stmtlist
            (stexpr (call (ident "say") (arglist (ident "x"))))
            (stexpr (assign (ident "u") (+ (ident "u") (- (int 1)))))))))
        .

    is-result $ast, "3\n2\n1\n", "the block parameter has the expected value";
}

{
    my $program = q:to/./;
        my u = 3;
        while u -> {
            u = u + -1;
        }
        say("alive");
        .

    outputs
        $program,
         "alive\n",
        "using -> without parameters in a block is allowed";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "u") (int 3))
          (while (ident "u") (block (paramlist (ident "a") (ident "b") (ident "c")) (stmtlist
            (stexpr (call (ident "say") (arglist (ident "x"))))
            (stexpr (assign (ident "u") (+ (ident "u") (- (int 1)))))))))
        .

    is-error $ast, X::ParameterMismatch, "while loops don't accept more than one parameter";
}

done-testing;
