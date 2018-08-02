use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        func f() { say("OH HAI from inside sub") }
        .

    outputs $program, "", "subs are not immediate";
}

{
    my $program = q:to/./;
        my x = "one";
        say(x);
        func f() {
            my x = "two";
            say(x);
        }
        f();
        say(x);
        .

    outputs $program, "one\ntwo\none\n", "subs have their own variable scope";
}

{
    my $program = q:to/./;
        func f(name) {
            say("Good evening, Mr " ~ name);
        }
        f("Bond");
        .

    outputs $program, "Good evening, Mr Bond\n", "calling a func with parameters works";
}

{
    my $program = q:to/./;
        func f(x, y) {
            say(x ~ y);
        }
        my y = "y";
        f("X", y ~ y);
        .

    outputs $program, "Xyy\n", "arguments are evaluated before parameters are bound";
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
    my $program = q:to/./;
        f();
        func f() {
            say("OH HAI from inside sub");
        }
        .

    outputs $program, "OH HAI from inside sub\n", "call a func before declaring it";
}

{
    my $program = q:to/./;
        f();
        my x = "X";
        func f() {
            say(x);
        }
        .

    outputs $program, "None\n", "using an outer lexical in a func that's called before the outer lexical's declaration";
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
    my $program = 'f("Bond"); func f(name) { say("Good evening, Mr " ~ name) }';

    outputs $program, "Good evening, Mr Bond\n", "calling a post-declared func works";
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
