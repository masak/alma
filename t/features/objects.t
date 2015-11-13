use v6;
use Test;
use _007::Test;

{
    my @exprs = «
        '{}'  "(object)"
        '{"a": 1}' '(object (property "a" (int 1)))'
        '{a}' '(object (property "a" (ident "a")))'
        '{a : 1}' '(object (property "a" (int 1)))'
        '{ a: 1}' '(object (property "a" (int 1)))'
        '{a: 1 }' '(object (property "a" (int 1)))'
        '{a: 1}' '(object (property "a" (int 1)))'
        '{a() {}}' '(object (property "a" (block (paramlist) (stmtlist))))'
        '{a(a, b) {}}' '(object (property "a" (block
          (paramlist (ident "a") (ident "b")) (stmtlist))))'
    »;

    for @exprs -> $expr, $frag {
        my $ast = qq[(stmtlist (my (ident "a")) (stexpr {$frag}))];

        parses-to "my a; ($expr)", $ast, $expr;
    }
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "o")
            (object (property "a" (int 1))))
          (stexpr (call (ident "say") (arglist
            (access (ident "o") (ident "a"))))))
        .

    is-result $ast, "1\n", "can access an object's property (dot syntax)";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "o")
            (object (property "b" (int 7))))
          (stexpr (call (ident "say") (arglist
            (index (ident "o") (str "b"))))))
        .

    is-result $ast, "7\n", "can access an object's property (brackets syntax)";
}

{
    my $ast = q:to/./;
          (stmtlist
            (my (ident "o") (object))
            (stexpr (access (ident "o") (ident "a"))))
        .

    is-error $ast, X::PropertyNotFound, "can't access non-existing property (dot syntax)";
}

{
    my $ast = q:to/./;
          (stmtlist
            (my (ident "o") (object))
            (stexpr (index (ident "o") (str "b"))))
        .

    is-error $ast, X::PropertyNotFound, "can't access non-existing property (brackets syntax)";
}

{
    my $program = q:to/./;
        my o = { bond: 7 };

        say(o.has("bond"));
        say(o.has("james"));

        say(o.get("bond"));
        .

    outputs
        $program,
        "1\n0\n7\n",
        "built-in pseudo-inherited methods on objects";
}

done-testing;
