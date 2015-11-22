use v6;
use Test;
use _007::Test;

{
    my @exprs = «
        '{}'  '(object (ident "Object") (proplist))'
        '{"a": 1}' '(object (ident "Object") (proplist (property "a" (int 1))))'
        '{a}' '(object (ident "Object") (proplist (property "a" (ident "a"))))'
        '{a : 1}' '(object (ident "Object") (proplist (property "a" (int 1))))'
        '{ a: 1}' '(object (ident "Object") (proplist (property "a" (int 1))))'
        '{a: 1 }' '(object (ident "Object") (proplist (property "a" (int 1))))'
        '{a: 1}' '(object (ident "Object") (proplist (property "a" (int 1))))'
        '{a() {}}' '(object (ident "Object") (proplist
          (property "a" (block (paramlist) (stmtlist)))))'
        '{a(a, b) {}}' '(object (ident "Object") (proplist (property "a" (block
          (paramlist (ident "a") (ident "b")) (stmtlist)))))'
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
            (object (ident "Object") (proplist (property "a" (int 1)))))
          (stexpr (postfix:<()> (ident "say") (arglist
            (postfix:<.> (ident "o") (ident "a"))))))
        .

    is-result $ast, "1\n", "can access an object's property (dot syntax)";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "o")
            (object (ident "Object") (proplist (property "b" (int 7)))))
          (stexpr (postfix:<()> (ident "say") (arglist
            (postfix:<[]> (ident "o") (str "b"))))))
        .

    is-result $ast, "7\n", "can access an object's property (brackets syntax)";
}

{
    my $ast = q:to/./;
          (stmtlist
            (my (ident "o") (object (ident "Object") (proplist)))
            (stexpr (postfix:<.> (ident "o") (ident "a"))))
        .

    is-error $ast, X::PropertyNotFound, "can't access non-existing property (dot syntax)";
}

{
    my $ast = q:to/./;
          (stmtlist
            (my (ident "o") (object (ident "Object") (proplist)))
            (stexpr (postfix:<[]> (ident "o") (str "b"))))
        .

    is-error $ast, X::PropertyNotFound, "can't access non-existing property (brackets syntax)";
}

{
    my $program = q:to/./;
        my o = { james: "bond", bond: 7 };

        say(o.has("bond"));
        say(o.has("jimmy"));

        say(o.get("bond"));

        say(o.update({ bond: 8 }));

        say({ x: 1 }.extend({ y: 2 }));

        my n = o.id;
        say("id");
        .

    outputs
        $program,
        qq[1\n0\n7\n\{bond: 8, james: "bond"\}\n\{x: 1, y: 2\}\nid\n],
        "built-in pseudo-inherited methods on objects";
}

{
    my $program = q:to/./;
        my q = Q::Identifier { name: "foo" };

        say(q.name);
        .

    outputs
        $program,
        qq[foo\n],
        "object literal syntax prefixed by type";
}

{
    my $program = q:to/./;
        my q = Q::Identifier { dunnexist: "foo" };
        .

    parse-error
        $program,
        X::Property::NotDeclared,
        "the object property doesn't exist on that type";
}

done-testing;
