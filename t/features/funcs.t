use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stfunc (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "OH HAI from inside sub"))))))))
        .

    is-result $ast, "", "subs are not immediate";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "x") (str "one"))
          (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x"))))
          (stfunc (identifier "f") (block (parameterlist) (statementlist
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
          (stfunc (identifier "f") (block (parameterlist (param (identifier "name"))) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (str "Good evening, Mr ") (identifier "name"))))))))
          (stexpr (postfix:() (identifier "f") (argumentlist (str "Bond")))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a func with parameters works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stfunc (identifier "f") (block (parameterlist (param (identifier "X")) (param (identifier "Y"))) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (identifier "X") (identifier "Y"))))))))
          (my (identifier "X") (str "y"))
          (stexpr (postfix:() (identifier "f") (argumentlist (str "X") (infix:~ (identifier "X") (identifier "X"))))))
        .

    is-result $ast, "Xyy\n", "argumentlist are evaluated before parameters are bound";
}

{
    my $program = q:to/./;
        func f(callback) {
            my scoping = "dynamic";
            callback();
        }
        my scoping = "lexical";
        f(func() { say(scoping) });
        .

    outputs $program, "lexical\n", "scoping is lexical";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "f") (argumentlist)))
          (stfunc (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "OH HAI from inside sub"))))))))
        .

    is-result $ast, "OH HAI from inside sub\n", "call a func before declaring it";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "f") (argumentlist)))
          (my (identifier "x") (str "X"))
          (stfunc (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (identifier "x"))))))))
        .

    is-result $ast, "None\n", "using an outer lexical in a func that's called before the outer lexical's declaration";
}

{
    my $program = q:to/./;
        func f() { say("OH HAI") }
        func g() { return f };
        g()();
        .

    outputs $program, "OH HAI\n",
        "left hand of a call doesn't have to be an identifier, just has to resolve to a callable";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:() (identifier "f") (argumentlist (str "Bond"))))
          (stfunc (identifier "f") (block (parameterlist (param (identifier "name"))) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (infix:~ (str "Good evening, Mr ") (identifier "name")))))))))
        .

    is-result $ast, "Good evening, Mr Bond\n", "calling a post-declared func works (I)";
}

{
    my $program = 'f("Bond"); func f(name) { say("Good evening, Mr " ~ name) }';

    outputs $program, "Good evening, Mr Bond\n", "calling a post-declared func works (II)";
}

{
    my $program = 'my b = 42; func g() { say(b) }; g()';

    outputs $program, "42\n", "lexical scope works correctly from inside a sub";
}

{
    my $program = q:to/./;
        func f() {}
        f = 5;
        .

    parse-error
        $program,
        X::Assignment::RO,
        "cannot assign to a subroutine (#68)";
}

{
    my $program = q:to/./;
        func f() {}
        func h(a, b, f) {
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
        my f = func (x) { say(x) };
        f("Mr Bond");
        .

    outputs $program,
        "Mr Bond\n",
        "expression subs work";
}

{
    my $program = q:to/./;
        my f = func g(x) { say(x) };
        f("Mr Bond");
        .

    outputs $program,
        "Mr Bond\n",
        "expression subs can be named, too";
}

{
    my $program = q:to/./;
        my f = func g(x) {};
        say(f);
        .

    outputs $program,
        "<func g(x)>\n",
        "...and they know their own name";
}

{
    my $program = q:to/./;
        my f = func g() { say(g) };
        f();
        .

    outputs $program,
        "<func g()>\n",
        "the name of a func is visible inside the sub...";
}

{
    my $program = q:to/./;
        my f = func g() {};
        g();
        .

    parse-error $program,
        X::Undeclared,
        "...but not outside of the sub";
}

{
    my $program = q:to/./;
        my f = func () {
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
        func f(x,) { }
        func g(x,y,) { }
        .

    outputs $program, "", "trailing commas are allowed in parameterlist";
}

{
    my $program = q:to/./;
        func f(x)   { say(1) }
        func g(x,y) { say(2) }
        f(4,);
        g(4,5,);
        .

    outputs $program, "1\n2\n", "...and in argumentlist";
}

{
    my $program = 'func subtract(x) { say(x) }; subtract("Mr Bond")';

    outputs $program, "Mr Bond\n", "it's OK to call your func 'subtract'";
}

{
    my $program = q:to/./;
        func fn()
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
        func b(count) {
            if count {
                b(count - 1);
                say(count);
            }
        }
        b(4);
        .

    outputs $program, "1\n2\n3\n4\n", "each func invocation gets its own callframe/scope";
}

{
    my $program = q:to/./;
        say(func () {});
        .

    outputs $program, "<func ()>\n", "an anonymous func stringifies without a name";
}

done-testing;
