use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say(38 + 4);
        .

    outputs $program, "42\n", "addition works";
}

{
    my $program = q:to/./;
        say(46 - 4);
        .

    outputs $program, "42\n", "subtraction works";
}

{
    my $program = q:to/./;
        say(6 * 7);
        .

    outputs $program, "42\n", "multiplication works";
}

{
    my $program = q:to/./;
        say(5 % 2);
        .

    outputs $program, "1\n", "modulo works";
}

{
    my $program = q:to/./;
        say(5 % -2);
        .

    outputs $program, "-1\n", "sign of modulo operation follows sign of divisor (rhs)";
}

{
    my $program = q:to/./;
        say(5 % 0);
        .

    runtime-error
        $program,
        X::Numeric::DivideByZero,
        "modulo by 0 is an error";
}

{
    my $program = q:to/./;
        say(5 %% 2);
        say(6 %% 2);
        say(5 %% -2);
        say(6 %% -2);
        .

    outputs $program, "False\nTrue\nFalse\nTrue\n", "divisibility operator works";
}

{
    my $program = q:to/./;
        say(5 %% 0);
        .

    runtime-error
        $program,
        X::Numeric::DivideByZero,
        "checking divisibility by 0 is an error";
}

{
    my $program = q:to/./;
        say("Jame" ~ "s Bond");
        .

    outputs $program, "James Bond\n", "string concatenation works";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[1]);
        .

    outputs $program, "Bond\n", "array indexing works";
}

{
    my $program = q:to/./;
        my ns = [["Auric", "Goldfinger"]];
        say(ns[0][1]);
        .

    outputs $program, "Goldfinger\n", "array indexing works on something that is not a variable name";
}

{
    my $program = q:to/./;
        my x = 1;
        x = 2;
        say(x);
        .

    outputs $program, "2\n", "assignment works";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my i2 = 11;
        say(i1 == i1);
        say(i1 == i2);
        .

    outputs $program, "True\nFalse\n", "integer equality";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my i2 = 11;
        say(i1 != i1);
        say(i1 != i2);
        .

    outputs $program, "False\nTrue\n", "integer inequality";
}

{
    my $program = q:to/./;
        my s1 = "s1";
        my s2 = "s2";
        say(s1 == s1);
        say(s1 == s2);
        .

    outputs $program, "True\nFalse\n", "string equality";
}

{
    my $program = q:to/./;
        my s1 = "s1";
        my s2 = "s2";
        say(s1 != s1);
        say(s1 != s2);
        .

    outputs $program, "False\nTrue\n", "string inequality";
}

{
    my $program = q:to/./;
        my s1 = "a";
        my s2 = "b";
        say(s1 < s1);
        say(s1 < s2);
        .

    outputs $program, "False\nTrue\n", "string less-than";
}

{
    my $program = q:to/./;
        my s1 = "b";
        my s2 = "a";
        say(s1 > s1);
        say(s1 > s2);
        .

    outputs $program, "False\nTrue\n", "string greater-than";
}

{
    my $program = q:to/./;
        my a1 = [1, 2, 3];
        my a2 = [1, 2, "3"];
        say(a1 == a1);
        say(a1 == a2);
        .

    outputs $program, "True\nFalse\n", "array equality";
}
        
{
    my $program = q:to/./;
        my a1 = [1, 2, 3];
        my a2 = [1, 2, "3"];
        say(a1 != a1);
        say(a1 != a2);
        .

    outputs $program, "False\nTrue\n", "array inequality";
}

{
    my $program = q:to/./;
        my a3 = [1, 2, 3];
        a3[1] = a3;
        say(a3 == a3);
        .

    outputs $program, "True\n", "nested array equality";
}

{
    my $program = q:to/./;
        my o1 = { x: 7 };
        my o2 = { x: 9 };
        say(o1 == o1);
        say(o1 == o2);
        .

    outputs $program, "True\nFalse\n", "object equality";
}

{
    my $program = q:to/./;
        my o1 = { x: 7 };
        my o2 = { x: 9 };
        say(o1 != o1);
        say(o1 != o2);
        .

    outputs $program, "False\nTrue\n", "object inequality";
}

{
    my $program = q:to/./;
        my o3 = { x: 7 };
        o3.y = o3;
        say(o3 == o3);
        .

    outputs $program, "True\n", "nested object equality";
}

{
    my $program = q:to/./;
        say(Int == Int);
        say(Int == Str);
        .

    outputs $program, "True\nFalse\n", "type equality";
}

{
    my $program = q:to/./;
        say(Int != Int);
        say(Int != Str);
        .

    outputs $program, "False\nTrue\n", "type inequality";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my s1 = "10";
        my a1 = [1, 2, 3];
        my o1 = { x: 7 };
        say(i1 == s1);
        say(s1 == a1);
        say(a1 == i1);
        say(o1 == i1);
        .

    outputs $program, "False\n" x 4, "equality testing across types (always False)";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my s1 = "10";
        my a1 = [1, 2, 3];
        my o1 = { x: 7 };
        say(i1 != s1);
        say(s1 != a1);
        say(a1 != i1);
        say(o1 != i1);
        .

    outputs $program, "True\n" x 4, "inequality testing across types (always True)";
}

{
    outputs 'func foo() {}; say(foo == foo)', "True\n", "a func is equal to itself";
    outputs 'macro foo() {}; say(foo == foo)', "True\n", "a macro is equal to itself";
    outputs 'say(say == say)', "True\n", "a built-in func is equal to itself";
    outputs 'say(infix:<+> == infix:<+>)', "True\n", "a built-in operator is equal to itself";
    outputs 'say(new Q.Identifier { name: "foo" } == new Q.Identifier { name: "foo" })', "True\n",
        "two Qtrees with equal content are equal";
    outputs 'my a = []; for [1, 2] { func fn() {}; a = [fn, a] }; say(a[1][0] == a[0])',
        "False\n", "the same func from two different frames are different";
    outputs 'func foo() {}; my x = foo; { func foo() {}; say(x == foo) }', "False\n",
        "distinct funcs are unequal, even with the same name and bodies (I)";
    outputs 'func foo() { say("OH HAI") }; my x = foo; { func foo() { say("OH HAI") }; say(x == foo) }',
        "False\n", "distinct funcs are unequal, even with the same name and bodies (II)";

    outputs 'func foo() {}; func bar() {}; say(foo == bar)', "False\n",
        "distinct funcs are unequal";
    outputs 'macro foo() {}; macro bar() {}; say(foo == bar)', "False\n",
        "distinct macros are unequal";
    outputs 'say(say == type)', "False\n", "distinct built-in funcs are unequal";
    outputs 'say(infix:<+> == prefix:<->)', "False\n",
        "distinct built-in operators are unequal";
    outputs 'func foo(y) {}; my x = foo; { func foo(x) {}; say(x == foo) }', "False\n",
        "funcs with different parameters are unequal";
    outputs 'func foo() {}; my x = foo; { func foo() { say("OH HAI") }; say(x == foo) }', "False\n",
        "funcs with different bodies are unequal";
    outputs 'say(new Q.Identifier { name: "foo" } == new Q.Identifier { name: "bar" })', "False\n",
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
    my $program = q:to/./;
        say(None == None);
        say(None == 0);
        say(None == "");
        say(None == []);
        .

    outputs $program, "True\nFalse\nFalse\nFalse\n", "equality testing with None matches only itself";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[-2]);
        .

    runtime-error
        $program,
        X::Subscript::Negative,
        "negative array indexing is an error";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[19]);
        .

    runtime-error
        $program,
        X::Subscript::TooLarge,
        "indexing beyond the last element is an error";
}

{
    my $program = q:to/./;
        say(38 + "4");
        .

    runtime-error
        $program,
        X::TypeCheck,
        "adding non-ints is an error";
}

{
    my $program = q:to/./;
        say(38 ~ "4");
        .

    outputs $program, "384\n", "concatenating non-strs is OK (since #281)";
}

{
    my $program = q:to/./;
        my ns = "Jim";
        say(ns[0]);
        .

    runtime-error
        $program,
        X::TypeCheck,
        "indexing a non-array is an error";
}

{
    my $program = q:to/./;
        my a = [1, 2, 3];
        func f() { return 7 };
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
        say(1 + 2 * 3);
        say(2 * 3 + 4);

        say(1 - 2 * 3);
        say(2 * 3 - 4);
        .

    outputs $program, "7\n10\n-5\n2\n", "multiplication is tighter than addition/subtraction";
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
    my $program = q:to/./;
        ^"Mr Bond"
        .

    runtime-error
        $program,
        X::TypeCheck,
        "can't upto a string (or other non-integer types)";
}

{
    my $program = q:to/./;
        my q = quasi<Q.Infix> { + }; say(q ~~ Q.Infix)
        .

    outputs $program, "True\n", "successful typecheck";
}

{
    my $program = q:to/./;
        my q = quasi<Q.Infix> { + }; say(q ~~ Q.Prefix)
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
        say(quasi<Q.Infix> { + } !~~ Q.Infix);
        say(quasi<Q.Infix> { + } !~~ Q.Prefix);
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
        func f() {
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
    my $program = q:to/./;
        say(type(+"6"));
        say(type(+"-6"));
        .

    outputs $program, "<type Int>\n<type Int>\n", "prefix:<+> works";
}

{
    my $program = q:to/./;
        say(type(~6));
        .

    outputs $program, "<type Str>\n", "prefix:<~> works";
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

{
    my $program = q:to/./;
        say( 5 divmod 2 );
        say( 5 divmod -2 );
        .

    outputs
        $program,
        "(2, 1)\n(-3, -1)\n",
        "divmod operator (happy path)";
}

{
    my $program = q:to/./;
        say( 5 divmod 0 );
        .

    runtime-error
        $program,
        X::Numeric::DivideByZero,
        "divmodding by 0 is an error";
}

done-testing;
