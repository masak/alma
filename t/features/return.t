use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (paramlist) (stmtlist
            (return (int 7)))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "f") (arglist))))))
        .

    is-result $ast, "7\n", "sub returning an Int";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (paramlist) (stmtlist
            (return (str "Bond. James Bond.")))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "f") (arglist))))))
        .

    is-result $ast, "Bond. James Bond.\n", "sub returning a Str";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (paramlist) (stmtlist
            (return (array (int 1) (int 2) (str "three"))))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "f") (arglist))))))
        .

    is-result $ast, qq|[1, 2, "three"]\n|, "sub returning an Array";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (paramlist) (stmtlist
            (return (int 1953))
            (stexpr (postfix:<()> (identifier "say") (arglist (str "Dead code. Should have returned by now.")))))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "f") (arglist))))))
        .

    is-result $ast, "1953\n", "a return statement forces immediate exit of the subroutine";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (paramlist) (stmtlist
            (my (identifier "b") (block (paramlist) (stmtlist
              (return (int 5)))))
            (sub (identifier "g") (block (paramlist) (stmtlist
              (stexpr (postfix:<()> (identifier "b") (arglist))))))
            (stexpr (postfix:<()> (identifier "g") (arglist)))
            (stexpr (postfix:<()> (identifier "say") (arglist (str "Dead code. Should have returned from f.")))))))
          (stexpr (postfix:<()> (identifier "f") (arglist))))
        .

    is-result $ast, "", "return statements bind lexically to their surrounding subroutine";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (paramlist) (stmtlist
            (my (identifier "b") (block (paramlist) (stmtlist
              (return (int 5)))))
            (return (identifier "b")))))
          (my (identifier "c") (postfix:<()> (identifier "f") (arglist)))
          (stexpr (postfix:<()> (identifier "c") (arglist))))
        .

    is-error $ast, X::ControlFlow::Return, "cannot run a return statement of a subroutine that already exited";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (paramlist) (stmtlist
            (return))))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<()> (identifier "f") (arglist))))))
        .

    is-result $ast, "None\n", "sub returning nothing";
}

done-testing;
