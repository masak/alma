use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (return (int 7))))
          (stexpr (call (ident "say") (arguments (call (ident "f") (arguments))))))
        .

    is-result $ast, "7\n", "sub returning an Int";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (return (str "Bond. James Bond."))))
          (stexpr (call (ident "say") (arguments (call (ident "f") (arguments))))))
        .

    is-result $ast, "Bond. James Bond.\n", "sub returning a Str";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (return (array (int 1) (int 2) (str "three")))))
          (stexpr (call (ident "say") (arguments (call (ident "f") (arguments))))))
        .

    is-result $ast, "[1, 2, three]\n", "sub returning an Array";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (return (int 1953))
            (stexpr (call (ident "say") (arguments (str "Dead code. Should have returned by now."))))))
          (stexpr (call (ident "say") (arguments (call (ident "f") (arguments))))))
        .

    is-result $ast, "1953\n", "a return statement forces immediate exit of the subroutine";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (my (ident "b") (assign (ident "b") (block (parameters) (statements
              (return (int 5))))))
            (sub (ident "g") (parameters) (statements
              (stexpr (call (ident "b") (arguments)))))
            (stexpr (call (ident "g") (arguments)))
            (stexpr (call (ident "say") (arguments (str "Dead code. Should have returned from f."))))))
          (stexpr (call (ident "f") (arguments))))
        .

    is-result $ast, "", "return statements bind lexically to their surrounding subroutine";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (my (ident "b") (assign (ident "b") (block (parameters) (statements
              (return (int 5))))))
            (return (ident "b"))))
          (my (ident "c") (assign (ident "c") (call (ident "f") (arguments))))
          (stexpr (call (ident "c") (arguments))))
        .

    is-error $ast, X::ControlFlow::Return, "cannot run a return statement of a subroutine that already exited";
}

{
    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (return)))
          (stexpr (call (ident "say") (arguments (call (ident "f") (arguments))))))
        .

    is-result $ast, "None\n", "sub returning nothing";
}

done;
