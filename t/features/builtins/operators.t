use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<+> (int 38) (int 4))))))
        .

    is-result $ast, "42\n", "numeric addition works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<-> (int 46) (int 4))))))
        .

    is-result $ast, "42\n", "numeric subtraction works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<*> (int 6) (int 7))))))
        .

    is-result $ast, "42\n", "numeric multiplication works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<~> (str "Jame") (str "s Bond"))))))
        .

    is-result $ast, "James Bond\n", "string concatenation works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<x> (str "hi ") (int 3))))))
        .

    is-result $ast, "hi hi hi \n", "string repeatition works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<xx> (array (int 1) (int 2)) (int 3))))))
        .

    is-result $ast, "[1, 2, 1, 2, 1, 2]\n", "array repeatition works";
}

{
    my $ast = q:to/./;
    (statementlist
     (stexpr (postfix:<()> (identifier "say")
       (argumentlist
        (infix:<::> (int 0)
        (infix:<::> (int 0)
        (infix:<::> (int 7) (array))))))))
    .

    is-result $ast, "[0, 0, 7]\n", "cons works";
}

{
    my $ast = q:to/./;
    (statementlist
     (stexpr (postfix:<()> (identifier "say")
       (argumentlist
        (infix:<::> (array (int 0) (int 0))
        (array (int 7)))))))
    .

    is-result $ast, "[[0, 0], 7]\n", "cons works even on non-scalar values";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<[]> (identifier "ns") (int 1))))))
        .

    is-result $ast, "Bond\n", "array indexing works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (array (str "Auric") (str "Goldfinger"))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<[]> (postfix:<[]> (identifier "ns") (int 0)) (int 1))))))
        .

    is-result $ast, "Goldfinger\n", "array indexing works on something that is not a variable name";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "x") (int 1))
          (stexpr (infix:<=> (identifier "x") (int 2)))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "x")))))
        .

    is-result $ast, "2\n", "assignment works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "i2") (int 11))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "i1") (identifier "i1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "i1") (identifier "i2"))))))
        .

    is-result $ast, "1\n0\n", "integer equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "i2") (int 11))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "i1") (identifier "i1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "i1") (identifier "i2"))))))
        .

    is-result $ast, "0\n1\n", "integer inequality";
}


{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "s1") (str "10"))
          (my (identifier "s2") (str "11"))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "s1") (identifier "s1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "s1") (identifier "s2"))))))
        .

    is-result $ast, "1\n0\n", "string equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "s1") (str "10"))
          (my (identifier "s2") (str "11"))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "s1") (identifier "s1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "s1") (identifier "s2"))))))
        .

    is-result $ast, "0\n1\n", "string inequality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "a2") (array (int 1) (int 2) (str "3")))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "a1") (identifier "a1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "a1") (identifier "a2"))))))
        .

    is-result $ast, "1\n0\n", "array equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "a2") (array (int 1) (int 2) (str "3")))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "a1") (identifier "a1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "a1") (identifier "a2"))))))
        .

    is-result $ast, "0\n1\n", "array inequality";
}


{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))
          (my (identifier "o2") (object (identifier "Object") (propertylist (property "x" (int 9)))))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "o1") (identifier "o1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "o1") (identifier "o2"))))))
        .

    is-result $ast, "1\n0\n", "object equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))
          (my (identifier "o2") (object (identifier "Object") (propertylist (property "x" (int 9)))))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "o1") (identifier "o1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "o1") (identifier "o2"))))))
        .

    is-result $ast, "0\n1\n", "object inequality";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "Int") (identifier "Int")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "Int") (identifier "Str"))))))
        .

    is-result $ast, "1\n0\n", "type equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "Int") (identifier "Int")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "Int") (identifier "Str"))))))
        .

    is-result $ast, "0\n1\n", "type inequality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "s1") (str "10"))
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "i1") (identifier "s1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "s1") (identifier "a1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "a1") (identifier "i1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "o1") (identifier "i1"))))))
        .

    is-result $ast, "0\n0\n0\n0\n", "equality testing across types (always false)";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "s1") (str "10"))
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "i1") (identifier "s1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "s1") (identifier "a1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "a1") (identifier "i1")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<!=> (identifier "o1") (identifier "i1"))))))
        .

    is-result $ast, "1\n1\n1\n1\n", "inequality testing across types (always true)";
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
    outputs 'say(say == min)', "0\n", "distinct built-in subs are unequal";
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
    outputs 'say(1 < 2); say(2 > 1); say(1 <= 2); say(2 <= 0)', "1\n1\n1\n0\n",
        "relational operators work on integers";
    outputs 'say("a" < "b"); say("b" > "a"); say("a" <= "c"); say("a" <= "B")', "1\n1\n1\n0\n",
        "relational operators work on strings";
}

{
    outputs 'say(!0); say(!1); say(1 || 0); say(0 || 1); say(0 && 1)', "1\n0\n1\n1\n0\n",
        "boolean operators give the values expected";
    outputs 'say(0 && say("foo")); say(1 || say("bar"))', "0\n1\n",
        "boolean operators short-circuit";
    outputs 'say(1 && 2); say("" && 3); say(0 || None); say([0, 0, 7] || 0)', "2\n\nNone\n[0, 0, 7]\n",
        "boolean operators return one of their operands";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "empty") (block (parameterlist) (statementlist)))
          (my (identifier "none") (postfix:<()> (identifier "empty") (argumentlist)))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "none") (identifier "none")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "none") (int 0)))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "none") (str "")))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "none") (array))))))
        .

    is-result $ast, "1\n0\n0\n0\n", "equality testing with none matches itself but nothing else";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<[]> (identifier "ns") (prefix:<-> (int 2)))))))
        .

    is-error $ast, X::Subscript::Negative, "negative array indexing is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<[]> (identifier "ns") (int 19))))))
        .

    is-error $ast, X::Subscript::TooLarge, "indexing beyond the last element is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<+> (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "adding non-ints is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<~> (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "concatenating non-strs is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (str "Jim"))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<[]> (identifier "ns") (int 0))))))
        .

    is-error $ast, X::TypeCheck, "indexing a non-array is an error";
}

{
    my $program = q:to/./;
        my a = [1, 2, 3];
        sub f() { return 7 };
        my o = { foo: 12 };

        say(-a[1]);
        say(-f());
        say(-o.foo);

        say(!a[2]);
        say(!f());
        say(!o.foo);
        .

    outputs $program, "-2\n-7\n-12\n0\n0\n0\n", "all postfixes are tighter than both prefixes";
}

{
    my $program = q:to/./;
        say(!0 * 7);
        .

    outputs $program, "7\n", "boolean negation is tighter than multiplication";
}

{
    my $program = q:to/./;
        -1 * 2;
        .

    my $ast = q:to/./;
        (statementlist
          (stexpr (infix:<*> (prefix:<-> (int 1)) (int 2))))
        .

    parses-to $program, $ast, "numeric negation is tighter than multiplication";
}

{
    my $program = q:to/./;
        say(1 + 2 * 3);
        say(2 * 3 + 4);

        say(1 - 2 * 3);
        say(2 * 3 - 4);
        .

    outputs $program, "7\n10\n-5\n2\n", "multiplication is tighter than addition/subtraction";
}

{
    my $program = q:to/./;
        say("Jim" x 2 ~ " Bond");
        say("Jim " ~ "Bond" x 2);
        .

    outputs $program, "JimJim Bond\nJim BondBond\n", "string repetition is tighter than concatenation";
}

{
    my $program = q:to/./;
        say(!0 :: []);
        say(-1 :: []);
        say(1+2 :: []);
        say(3-4 :: []);
        say(5*6 :: []);
        say("B" x 2 :: []);
        say("Bo" ~ "nd" :: []);
        say([0] xx 2 :: [7]);
        .

    outputs $program, qq![1]\n[-1]\n[3]\n[-1]\n[30]\n["BB"]\n["Bond"]\n[[0, 0], 7]\n!,
        "cons is looser than even the additive infixes (+ - ~)";
}

{
    my $program = q:to/./;
        say(1 == 2 != 3);
        say(4 != 5 == 6);

        say(0 == 1 < 1);
        say(0 < 2 == 1);

        say(1 < 2 <= 1);
        say(0 <= 0 < 1);

        say(1 <= 2 >= 2);
        say(2 >= 2 <= 1);

        say(1 >= 2 > 2);
        say(2 > 2 >= 1);
        .

    outputs $program, "1\n0\n1\n1\n1\n0\n0\n1\n0\n0\n",
        "all of the comparison operators evaluate from left to right";
}

{
    my $program = q:to/./;
        say(0 == 0 && 1);
        say(2 == 2 && 3 == 3);
        .

    outputs $program, "1\n1\n", "&& binds looser than ==";
}

{
    my $program = q:to/./;
        say(0 && 1 || 1);
        say(1 || 0 && 0);
        .

    outputs $program, "1\n1\n", "&& binds tighter than ||";
}

{
    my $program = q:to/./;
        my x;

        x = 1 == 2;
        say(x);

        x = 0 || "foo";
        say(x);

        x = 1 && "bar";
        say(x);
        .

    outputs $program, "0\nfoo\nbar\n", "assignment binds looser than all the other operators";
}

{
    my $program = q:to/./;
        for ^3 -> n {
            say(n);
        }
        .

    outputs $program, "0\n1\n2\n", "upto operator works";
}

{
    my $program = q:to/./;
        for ^0 -> n {
            say(n);
        }
        for ^-3 -> n {
            say(n);
        }
        .

    outputs $program, "", "zero or negative numbers give an empty list for the upto operator";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (prefix:<^> (str "Mr Bond"))))
        .

    is-error $ast, X::TypeCheck, "can't upto a string (or other non-integer types)";
}

{
    my $program = q:to/./;
        my q = quasi @ Q::Infix { + }; say(q ~~ Q::Infix)
        .

    outputs $program, "1\n", "typecheck returns 1 on success";
}

{
    my $program = q:to/./;
        my q = quasi @ Q::Infix { + }; say(q ~~ Q::Prefix)
        .

    outputs $program, "0\n", "typecheck returns 0 on failure";
}

{
    my $program = q:to/./;
        my q = 42; say(q ~~ Int)
        .

    outputs $program, "1\n", "typecheck works for Val::Int";
}

{
    my $program = q:to/./;
        my q = [4, 2]; say(q ~~ Array)
        .

    outputs $program, "1\n", "typecheck works for Val::Array";
}

{
    my $program = q:to/./;
        my q = {}; say(q ~~ Object)
        .

    outputs $program, "1\n", "typecheck works for Val::Object";
}

done-testing;
