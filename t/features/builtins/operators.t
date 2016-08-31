use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:+ (int 38) (int 4))))))
        .

    is-result $ast, "42\n", "numeric addition works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:- (int 46) (int 4))))))
        .

    is-result $ast, "42\n", "numeric subtraction works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:* (int 6) (int 7))))))
        .

    is-result $ast, "42\n", "numeric multiplication works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:% (int 5) (int 2))))))
        .

    is-result $ast, "1\n", "numeric modulo works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:% (int 5) (prefix:- (int 2)))))))
        .

    is-result $ast, "-1\n", "sign of modulo operation follows sign of divisor (rhs)";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:% (int 5) (int 0))))))
        .

    is-error $ast, X::Numeric::DivideByZero, "dividing by 0 is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:%% (int 5) (int 2)))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:%% (int 6) (int 2)))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:%% (int 5) (prefix:- (int 2))))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:%% (int 6) (prefix:- (int 2)))))))
        .

    is-result $ast, "False\nTrue\nFalse\nTrue\n", "numeric divisibility works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:%% (int 5) (int 0))))))
        .

    is-error $ast, X::Numeric::DivideByZero, "checking divisibility by 0 is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (str "Jame") (str "s Bond"))))))
        .

    is-result $ast, "James Bond\n", "string concatenation works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:x (str "hi ") (int 3))))))
        .

    is-result $ast, "hi hi hi \n", "string repetition works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:xx (array (int 1) (int 2)) (int 3))))))
        .

    is-result $ast, "[1, 2, 1, 2, 1, 2]\n", "array repetition works";
}

{
    my $ast = q:to/./;
    (statementlist
     (stexpr (postfix:() (identifier "say")
       (argumentlist
        (infix::: (int 0)
        (infix::: (int 0)
        (infix::: (int 7) (array))))))))
    .

    is-result $ast, "[0, 0, 7]\n", "cons works";
}

{
    my $ast = q:to/./;
    (statementlist
     (stexpr (postfix:() (identifier "say")
       (argumentlist
        (infix::: (array (int 0) (int 0))
        (array (int 7)))))))
    .

    is-result $ast, "[[0, 0], 7]\n", "cons works even on non-scalar values";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:[] (identifier "ns") (int 1))))))
        .

    is-result $ast, "Bond\n", "array indexing works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (array (str "Auric") (str "Goldfinger"))))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:[] (postfix:[] (identifier "ns") (int 0)) (int 1))))))
        .

    is-result $ast, "Goldfinger\n", "array indexing works on something that is not a variable name";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "x") (int 1))
          (stexpr (infix:= (identifier "x") (int 2)))
          (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x")))))
        .

    is-result $ast, "2\n", "assignment works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "i2") (int 11))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "i1") (identifier "i1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "i1") (identifier "i2"))))))
        .

    is-result $ast, "True\nFalse\n", "integer equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "i2") (int 11))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "i1") (identifier "i1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "i1") (identifier "i2"))))))
        .

    is-result $ast, "False\nTrue\n", "integer inequality";
}


{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "s1") (str "10"))
          (my (identifier "s2") (str "11"))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "s1") (identifier "s1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "s1") (identifier "s2"))))))
        .

    is-result $ast, "True\nFalse\n", "string equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "s1") (str "10"))
          (my (identifier "s2") (str "11"))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "s1") (identifier "s1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "s1") (identifier "s2"))))))
        .

    is-result $ast, "False\nTrue\n", "string inequality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "a2") (array (int 1) (int 2) (str "3")))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "a1") (identifier "a1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "a1") (identifier "a2"))))))
        .

    is-result $ast, "True\nFalse\n", "array equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "a2") (array (int 1) (int 2) (str "3")))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "a1") (identifier "a1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "a1") (identifier "a2"))))))
        .

    is-result $ast, "False\nTrue\n", "array inequality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a3") (array (int 1) (int 2) (int 3)))

          (stexpr (infix:= (postfix:[] (identifier "a3") (int 1)) (identifier "a3")))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "a3") (identifier "a3"))))))
        .

    is-result $ast, "True\n", "nested array equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))
          (my (identifier "o2") (object (identifier "Object") (propertylist (property "x" (int 9)))))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "o1") (identifier "o1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "o1") (identifier "o2"))))))
        .

    is-result $ast, "True\nFalse\n", "object equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))
          (my (identifier "o2") (object (identifier "Object") (propertylist (property "x" (int 9)))))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "o1") (identifier "o1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "o1") (identifier "o2"))))))
        .

    is-result $ast, "False\nTrue\n", "object inequality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o3") (object (identifier "Object") (propertylist (property "x" (int 7)))))

          (stexpr (infix:= (postfix:. (identifier "o3") (identifier "y")) (identifier "o3")))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "o3") (identifier "o3"))))))
        .

    is-result $ast, "True\n", "nested object equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "Int") (identifier "Int")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "Int") (identifier "Str"))))))
        .

    is-result $ast, "True\nFalse\n", "type equality";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "Int") (identifier "Int")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "Int") (identifier "Str"))))))
        .

    is-result $ast, "False\nTrue\n", "type inequality";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "s1") (str "10"))
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "i1") (identifier "s1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "s1") (identifier "a1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "a1") (identifier "i1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "o1") (identifier "i1"))))))
        .

    is-result $ast, "False\nFalse\nFalse\nFalse\n", "equality testing across types (always false)";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "s1") (str "10"))
          (my (identifier "a1") (array (int 1) (int 2) (int 3)))
          (my (identifier "o1") (object (identifier "Object") (propertylist (property "x" (int 7)))))

          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "i1") (identifier "s1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "s1") (identifier "a1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "a1") (identifier "i1")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:!= (identifier "o1") (identifier "i1"))))))
        .

    is-result $ast, "True\nTrue\nTrue\nTrue\n", "inequality testing across types (always true)";
}

{
    outputs 'sub foo() {}; say(foo == foo)', "True\n", "a sub is equal to itself";
    outputs 'macro foo() {}; say(foo == foo)', "True\n", "a macro is equal to itself";
    outputs 'say(say == say)', "True\n", "a built-in sub is equal to itself";
    outputs 'say(infix:<+> == infix:<+>)', "True\n", "a built-in operator is equal to itself";
    outputs 'say(new Q::Identifier { name: "foo" } == new Q::Identifier { name: "foo" })', "True\n",
        "two Qtrees with equal content are equal";
    outputs 'my a = []; for [1, 2] { sub fn() {}; a = [fn, a] }; say(a[1][0] == a[0])',
        "True\n", "the same sub from two different frames compares favorably to itself";
    outputs 'sub foo() {}; my x = foo; { sub foo() {}; say(x == foo) }', "True\n",
        "subs with the same name and bodies are equal (I)";
    outputs 'sub foo() { say("OH HAI") }; my x = foo; { sub foo() { say("OH HAI") }; say(x == foo) }',
        "True\n", "subs with the same name and bodies are equal (II)";

    outputs 'sub foo() {}; sub bar() {}; say(foo == bar)', "False\n",
        "distinct subs are unequal";
    outputs 'macro foo() {}; macro bar() {}; say(foo == bar)', "False\n",
        "distinct macros are unequal";
    outputs 'say(say == type)', "False\n", "distinct built-in subs are unequal";
    outputs 'say(infix:<+> == prefix:<->)', "False\n",
        "distinct built-in operators are unequal";
    outputs 'sub foo(y) {}; my x = foo; { sub foo(x) {}; say(x == foo) }', "False\n",
        "subs with different parameters are unequal";
    outputs 'sub foo() {}; my x = foo; { sub foo() { say("OH HAI") }; say(x == foo) }', "False\n",
        "subs with different bodies are unequal";
    outputs 'say(new Q::Identifier { name: "foo" } == new Q::Identifier { name: "bar" })', "False\n",
        "two Qtrees with distinct content are unequal";
}

{
    outputs 'say(1 < 2); say(2 > 1); say(1 <= 2); say(2 <= 0)', "True\nTrue\nTrue\nFalse\n",
        "relational operators work on integers";
    outputs 'say("a" < "b"); say("b" > "a"); say("a" <= "c"); say("a" <= "B")', "True\nTrue\nTrue\nFalse\n",
        "relational operators work on strings";
}

{
    outputs 'say(!False); say(!True); say(True || False); say(False || True); say(False && True)',
        "True\nFalse\nTrue\nTrue\nFalse\n",
        "boolean operators give the values expected";
    outputs 'say(False && say("foo")); say(True || say("bar"))', "False\nTrue\n",
        "boolean operators short-circuit";
    outputs 'say(1 && 2); say("" && 3); say(False || None); say([0, 0, 7] || False)', "2\n\nNone\n[0, 0, 7]\n",
        "boolean operators return one of their operands";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "empty") (block (parameterlist) (statementlist)))
          (my (identifier "none") (postfix:() (identifier "empty") (argumentlist)))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "none") (identifier "none")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "none") (int 0)))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "none") (str "")))))
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:== (identifier "none") (array))))))
        .

    is-result $ast, "True\nFalse\nFalse\nFalse\n", "equality testing with none matches itself but nothing else";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:[] (identifier "ns") (prefix:- (int 2)))))))
        .

    is-error $ast, X::Subscript::Negative, "negative array indexing is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:[] (identifier "ns") (int 19))))))
        .

    is-error $ast, X::Subscript::TooLarge, "indexing beyond the last element is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:+ (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "adding non-ints is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (int 38) (str "4"))))))
        .

    is-error $ast, X::TypeCheck, "concatenating non-strs is an error";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (str "Jim"))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:[] (identifier "ns") (int 0))))))
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

    outputs $program, "-2\n-7\n-12\nFalse\nFalse\nFalse\n", "all postfixes are tighter than both prefixes";
}

{
    my $program = q:to/./;
        -1 * 2;
        .

    my $ast = q:to/./;
        (statementlist
          (stexpr (infix:* (prefix:- (int 1)) (int 2))))
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

    outputs $program, qq![True]\n[-1]\n[3]\n[-1]\n[30]\n["BB"]\n["Bond"]\n[[0, 0], 7]\n!,
        "cons is looser than even the additive infixes (+ - ~)";
}

{
    my $program = q:to/./;
        say(1 == 2 != 3);
        say(4 != 5 == 6);
        .

    outputs $program, "True\nFalse\n",
        "comparison operators evaluate from left to right";
}

{
    my $program = q:to/./;
        say(0 == 0 && "Bond");
        say(2 == 2 && 3 == 3);
        .

    outputs $program, "Bond\nTrue\n", "&& binds looser than ==";
}

{
    my $program = q:to/./;
        say(0 && 1 || "James");
        say(True || 0 && 0);
        .

    outputs $program, "James\nTrue\n", "&& binds tighter than ||";
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

    outputs $program, "False\nfoo\nbar\n", "assignment binds looser than all the other operators";
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
          (stexpr (prefix:^ (str "Mr Bond"))))
        .

    is-error $ast, X::TypeCheck, "can't upto a string (or other non-integer types)";
}

{
    my $program = q:to/./;
        my q = quasi @ Q::Infix { + }; say(q ~~ Q::Infix)
        .

    outputs $program, "True\n", "successful typecheck";
}

{
    my $program = q:to/./;
        my q = quasi @ Q::Infix { + }; say(q ~~ Q::Prefix)
        .

    outputs $program, "False\n", "unsuccessful typecheck";
}

{
    my $program = q:to/./;
        my q = 42; say(q ~~ Int)
        .

    outputs $program, "True\n", "typecheck works for Val::Int";
}

{
    my $program = q:to/./;
        my q = [4, 2]; say(q ~~ Array)
        .

    outputs $program, "True\n", "typecheck works for Val::Array";
}

{
    my $program = q:to/./;
        my q = {}; say(q ~~ Object)
        .

    outputs $program, "True\n", "typecheck works for Val::Object";
}

{
    my $program = q:to/./;
        say(quasi @ Q::Infix { + } !~~ Q::Infix);
        say(quasi @ Q::Infix { + } !~~ Q::Prefix);
        say(42 !~~ Int);
        say([4, 2] !~~ Array);
        say({} !~~ Object);
        say(42 !~~ Array);
        say([4, 2] !~~ Object);
        say({} !~~ Int);
        .

    outputs $program, "False\nTrue\nFalse\nFalse\nFalse\nTrue\nTrue\nTrue\n", "bunch of negative typechecks";
}

{
    my $program = q:to/./;
        say(42 // "oh, James");
        .

    outputs $program, "42\n", "defined-or with a defined lhs";
}

{
    my $program = q:to/./;
        say(None // "oh, James");
        .

    outputs $program, "oh, James\n", "defined-or with None as the lhs";
}

{
    my $program = q:to/./;
        say(0 // "oh, James");
        say("" // "oh, James");
        say([] // "oh, James");
        .

    outputs $program, "0\n\n[]\n", "0 and \"\" and [] are not truthy, but they *are* defined";
}

{
    my $program = q:to/./;
        sub f() {
            say("I never get run, you know");
        }
        say(007 // f());
        .

    outputs $program, "7\n", "short-circuiting: if the lhs is defined, the (thunkish) rhs never runs";
}

{
    my $program = q:to/./;
        say("a" == "a" ~~ Bool);
        say(7 ~~ Int == True);
        .

    outputs $program, "True\nTrue\n", "infix:<~~> has the tightness of a comparison operator";
}

{
    my $program = q:to/./;
        say(-"42");
        .

    outputs $program, "-42\n", "the prefix negation operator also numifies strings";
}

{
     my $ast = q:to/./;
         (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:() (identifier "type") (argumentlist (prefix:+ (str "6")))))))
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:() (identifier "type") (argumentlist (prefix:+ (str "-6"))))))))
        .

    is-result $ast, "<type Int>\n<type Int>\n", "prefix:<+> works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "say") (argumentlist (postfix:() (identifier "type") (argumentlist (prefix:~ (int 6))))))))
        .

    is-result $ast, "<type Str>\n", "prefix:<~> works";
}

{
    my $program = q:to/./;
        say( +7 ~~ Int );
        .

    outputs
        $program,
        "True\n",
        "+Val::Int outputs a Val::Int (regression)";
}

{
    my $program = q:to/./;
        say( +"007" ~~ Int );
        .

    outputs
        $program,
        "True\n",
        "+Val::Str outputs a Val::Int (regression)";
}

done-testing;
