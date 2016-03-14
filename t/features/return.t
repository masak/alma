use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (return (int 7)))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "f") (argumentlist))))))
        .

    is-result $ast, "7\n", "sub returning an Int";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (return (str "Bond. James Bond.")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "f") (argumentlist))))))
        .

    is-result $ast, "Bond. James Bond.\n", "sub returning a Str";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (return (array (int 1) (int 2) (str "three"))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "f") (argumentlist))))))
        .

    is-result $ast, qq|[1, 2, "three"]\n|, "sub returning an Array";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (return (int 1953))
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "Dead code. Should have returned by now.")))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "f") (argumentlist))))))
        .

    is-result $ast, "1953\n", "a return statement forces immediate exit of the subroutine";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (my (identifier "b") (block (parameterlist) (statementlist
              (return (int 5)))))
            (return (identifier "b")))))
          (my (identifier "c") (postfix:<()> (identifier "f") (argumentlist)))
          (stexpr (postfix:<()> (identifier "c") (argumentlist))))
        .

    is-error $ast, X::ControlFlow::Return, "cannot run a return statement of a subroutine that already exited";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (return))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "f") (argumentlist))))))
        .

    is-result $ast, "None\n", "sub returning nothing";
}

done-testing;
