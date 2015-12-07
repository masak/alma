use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<+> (int 38) (int 4))))))
        .

    is-result $ast, "42\n", "numeric addition works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<-> (int 46) (int 4))))))
        .

    is-result $ast, "42\n", "numeric subtraction works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<*> (int 6) (int 7))))))
        .

    is-result $ast, "42\n", "numeric multiplication works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<~> (str "Jame") (str "s Bond"))))))
        .

    is-result $ast, "James Bond\n", "string concatenation works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<[]> (ident "ns") (int 1))))))
        .

    is-result $ast, "Bond\n", "array indexing works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "ns") (array (array (str "Auric") (str "Goldfinger"))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<[]> (postfix:<[]> (ident "ns") (int 0)) (int 1))))))
        .

    is-result $ast, "Goldfinger\n", "array indexing works on something that is not a variable name";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "x") (int 1))
          (stexpr (infix:<=> (ident "x") (int 2)))
          (stexpr (postfix:<()> (ident "say") (arglist (ident "x")))))
        .

    is-result $ast, "2\n", "assignment works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "i1") (int 10))
          (my (ident "i2") (int 11))

          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "i1") (ident "i1")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "i1") (ident "i2"))))))
        .

    is-result $ast, "1\n0\n", "integer equality";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "s1") (str "10"))
          (my (ident "s2") (str "11"))

          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "s1") (ident "s1")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "s1") (ident "s2"))))))
        .

    is-result $ast, "1\n0\n", "string equality";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "a1") (array (int 1) (int 2) (int 3)))
          (my (ident "a2") (array (int 1) (int 2) (str "3")))

          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "a1") (ident "a1")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "a1") (ident "a2"))))))
        .

    is-result $ast, "1\n0\n", "array equality";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "o1") (object (ident "Object") (proplist (property "x" (int 7)))))
          (my (ident "o2") (object (ident "Object") (proplist (property "x" (int 9)))))

          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "o1") (ident "o1")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "o1") (ident "o2"))))))
        .

    is-result $ast, "1\n0\n", "object equality";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "Int") (ident "Int")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "Int") (ident "Str"))))))
        .

    is-result $ast, "1\n0\n", "type equality";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "i1") (int 10))
          (my (ident "s1") (str "10"))
          (my (ident "a1") (array (int 1) (int 2) (int 3)))
          (my (ident "o1") (object (ident "Object") (proplist (property "x" (int 7)))))

          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "i1") (ident "s1")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "s1") (ident "a1")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "a1") (ident "i1")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "o1") (ident "i1"))))))
        .

    is-result $ast, "0\n0\n0\n0\n", "equality testing across types (always false)";
}

{
    outputs 'sub foo() {}; say(foo == foo)', "1\n", "a sub is equal to itself";
    outputs 'macro foo() {}; say(foo == foo)', "1\n", "a macro is equal to itself";
    outputs 'say(say == say)', "1\n", "a built-in sub is equal to itself";
    outputs 'say(infix:<+> == infix:<+>)', "1\n", "a built-in operator is equal to itself";
    outputs 'say(Q::Identifier { name: "foo" } == Q::Identifier { name: "foo" })', "1\n",
        "two Qtrees with equal content are equal";
    outputs 'my a = []; for [1, 2] { sub fn() {}; a = [fn, a] }; say(a[1][0] == a[0])',
        "1\n", "the same sub from two different frames compares favorably to itself";
    outputs 'sub foo() {}; my x = foo; { sub foo() {}; say(x == foo) }', "1\n",
        "subs with the same name and bodies are equal (I)";
    outputs 'sub foo() { say("OH HAI") }; my x = foo; { sub foo() { say("OH HAI") }; say(x == foo) }',
        "1\n", "subs with the same name and bodies are equal (II)";

    outputs 'sub foo() {}; sub bar() {}; say(foo == bar)', "0\n",
        "distinct subs are unequal";
    outputs 'macro foo() {}; macro bar() {}; say(foo == bar)', "0\n",
        "distinct macros are unequal";
    outputs 'say(say == chr)', "0\n", "distinct built-in subs are unequal";
    outputs 'say(infix:<+> == prefix:<->)', "0\n",
        "distinct built-in operators are unequal";
    outputs 'sub foo(y) {}; my x = foo; { sub foo(x) {}; say(x == foo) }', "0\n",
        "subs with different parameters are unequal";
    outputs 'sub foo() {}; my x = foo; { sub foo() { say("OH HAI") }; say(x == foo) }', "0\n",
        "subs with different bodies are unequal";
    outputs 'say(Q::Identifier { name: "foo" } == Q::Identifier { name: "bar" })', "0\n",
        "two Qtrees with distinct content are unequal";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "empty") (block (paramlist) (stmtlist)))
          (my (ident "none") (postfix:<()> (ident "empty") (arglist)))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "none") (ident "none")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "none") (int 0)))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "none") (str "")))))
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<==> (ident "none") (array))))))
        .

    is-result $ast, "1\n0\n0\n0\n", "equality testing with none matches itself but nothing else";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<[]> (ident "ns") (prefix:<-> (int 2)))))))
        .

    is-error $ast, X::Subscript::Negative, "negative array indexing is an error";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<[]> (ident "ns") (int 19))))))
        .

    is-error $ast, X::Subscript::TooLarge, "indexing beyond the last element is an error";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<+> (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "adding non-ints is an error";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (infix:<~> (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "concatenating non-strs is an error";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "ns") (str "Jim"))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<[]> (ident "ns") (int 0))))))
        .

    is-error $ast, X::TypeCheck, "indexing a non-array is an error";
}

done-testing;
