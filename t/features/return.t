use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (return (int 7)))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "f") (arglist))))))
        .

    is-result $ast, "7\n", "sub returning an Int";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (return (str "Bond. James Bond.")))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "f") (arglist))))))
        .

    is-result $ast, "Bond. James Bond.\n", "sub returning a Str";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (return (array (int 1) (int 2) (str "three"))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "f") (arglist))))))
        .

    is-result $ast, qq|[1, 2, "three"]\n|, "sub returning an Array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (return (int 1953))
            (stexpr (postfix:<()> (ident "say") (arglist (str "Dead code. Should have returned by now.")))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "f") (arglist))))))
        .

    is-result $ast, "1953\n", "a return statement forces immediate exit of the subroutine";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (my (ident "b") (block (paramlist) (stmtlist
              (return (int 5)))))
            (sub (ident "g") (block (paramlist) (stmtlist
              (stexpr (postfix:<()> (ident "b") (arglist))))))
            (stexpr (postfix:<()> (ident "g") (arglist)))
            (stexpr (postfix:<()> (ident "say") (arglist (str "Dead code. Should have returned from f.")))))))
          (stexpr (postfix:<()> (ident "f") (arglist))))
        .

    is-result $ast, "", "return statements bind lexically to their surrounding subroutine";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (my (ident "b") (block (paramlist) (stmtlist
              (return (int 5)))))
            (return (ident "b")))))
          (my (ident "c") (postfix:<()> (ident "f") (arglist)))
          (stexpr (postfix:<()> (ident "c") (arglist))))
        .

    is-error $ast, X::ControlFlow::Return, "cannot run a return statement of a subroutine that already exited";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist
            (return))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "f") (arglist))))))
        .

    is-result $ast, "None\n", "sub returning nothing";
}

done-testing;
