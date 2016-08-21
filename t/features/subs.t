use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "OH HAI from inside sub"))))))))
        .

    is-result $ast, "", "subs are not immediate";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "x") (str "one"))
          (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x"))))
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (my (identifier "x") (str "two"))
            (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x")))))))
          (stexpr (postfix:() (identifier "f") (argumentlist)))
          (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x")))))
        .

    is-result $ast, "one\ntwo\none\n", "subs have their own variable scope";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist (param (identifier "name"))) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (str "Good evening, Mr ") (identifier "name"))))))))
          (stexpr (postfix:() (identifier "f") (argumentlist (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a sub with parameters works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist (param (identifier "X")) (param (identifier "Y"))) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (identifier "X") (identifier "Y"))))))))
          (my (identifier "X") (str "y"))
          (stexpr (postfix:() (identifier "f") (argumentlist (str "X") (infix:~ (identifier "X") (identifier "X"))))))
        .

    is-result $ast, "Xyy\n", "argumentlist are evaluated before parameters are bound";
}

{
    my $program = q:to/./;
        sub f(callback) {
            my scoping = "dynamic";
            callback();
        }
        my scoping = "lexical";
        f(sub() { say(scoping) });
        .

    outputs $program, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "f") (argumentlist)))
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "OH HAI from inside sub"))))))))
        .

    is-result $ast, "OH HAI from inside sub\n", "call a sub before declaring it";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "f") (argumentlist)))
          (my (identifier "x") (str "X"))
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x"))))))))
        .

    is-result $ast, "None\n", "using an outer lexical in a sub that's called before the outer lexical's declaration";
}

{
    my $program = q:to/./;
        sub f() { say("OH HAI") }
        sub g() { return f };
        g()();
        .

    outputs $program, "OH HAI\n",
        "left hand of a call doesn't have to be an identifier, just has to resolve to a callable";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "f") (argumentlist (str "Bond"))))
          (stsub (identifier "f") (block (parameterlist (param (identifier "name"))) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (str "Good evening, Mr ") (identifier "name")))))))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a post-declared sub works (I)";
}

{
    my $program = 'f("Bond"); sub f(name) { say("Good evening, Mr " ~ name) }';

    outputs $program, "Good evening, Mr Bond\n", "calling a post-declared sub works (II)";
}

{
    my $program = 'my b = 42; sub g() { say(b) }; g()';

    outputs $program, "42\n", "lexical scope works correctly from inside a sub";
}

{
    my $program = q:to/./;
        sub f() {}
        f = 5;
        .

    parse-error
        $program,
        X::Assignment::RO,
        "cannot assign to a subroutine (#68)";
}

{
    my $program = q:to/./;
        sub f() {}
        sub h(a, b, f) {
            f = 17;
            say(f == 17);
        }
        h(0, 0, 7);
        say(f == 17);
        .

    outputs $program,
        "True\nFalse\n",
        "can assign to a parameter which hides a subroutine (#68)";
}

{
    my $program = q:to/./;
        my f = sub (x) { say(x) };
        f("Mr Bond");
        .

    outputs $program,
        "Mr Bond\n",
        "expression subs work";
}

{
    my $program = q:to/./;
        my f = sub g(x) { say(x) };
        f("Mr Bond");
        .

    outputs $program,
        "Mr Bond\n",
        "expression subs can be named, too";
}

{
    my $program = q:to/./;
        my f = sub g(x) {};
        say(f);
        .

    outputs $program,
        "<sub g(x)>\n",
        "...and they know their own name";
}

{
    my $program = q:to/./;
        my f = sub g() { say(g) };
        f();
        .

    outputs $program,
        "<sub g()>\n",
        "the name of a sub is visible inside the sub...";
}

{
    my $program = q:to/./;
        my f = sub g() {};
        g();
        .

    parse-error $program,
        X::Undeclared,
        "...but not outside of the sub";
}

{
    my $program = q:to/./;
        my f = sub () {
            my c = "Goldfinger";
            say(c);
        };

        f();
        .

    outputs $program,
        "Goldfinger\n",
        "can declare and use a variable in a term sub";
}

{
    my $program = q:to/./;
        sub f(x,) { }
        sub g(x,y,) { }
        .

    outputs $program, "", "trailing commas are allowed in parameterlist";
}

{
    my $program = q:to/./;
        sub f(x)   { say(1) }
        sub g(x,y) { say(2) }
        f(4,);
        g(4,5,);
        .

    outputs $program, "1\n2\n", "...and in argumentlist";
}

{
    my $program = 'sub subtract(x) { say(x) }; subtract("Mr Bond")';

    outputs $program, "Mr Bond\n", "it's OK to call your sub 'subtract'";
}

{
    my $program = q:to/./;
        sub fn()
        .

    my subset missing-block of X::Syntax::Missing where {
        is(.what, "block", "got the right missing thing");
        .what eq "block";
    };

    parse-error $program,
        missing-block,
        "parse error 'missing block' on missing block (#48)";
}

{
    my $program = q:to/./;
        sub b(count) {
            if count {
                b(count - 1);
                say(count);
            }
        }
        b(4);
        .

    outputs $program, "1\n2\n3\n4\n", "each sub invocation gets its own callframe/scope";
}

{
    my $program = q:to/./;
        say(sub () {});
        .

    outputs $program, "<sub ()>\n", "an anonymous sub stringifies without a name";
}

done-testing;
