use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my n = 7;
        .

    my $ast = q:to/./;
        (statements
          (my (ident "n") (assign (ident "n") (int 7))))
        .

    parses-to $program, $ast, "assigning an int";
}

{
    my $program = q:to/./;
        my s = "Bond";
        .

    my $ast = q:to/./;
        (statements
          (my (ident "s") (assign (ident "s") (str "Bond"))))
        .

    parses-to $program, $ast, "assigning a str";
}

{
    my $program = q:to/./;
        my a = [1, 2];
        .

    my $ast = q:to/./;
        (statements
          (my (ident "a") (assign (ident "a") (array (int 1) (int 2)))))
        .

    parses-to $program, $ast, "assigning an array";
}

{
    my $program = q:to/./;
        my u;
        .

    my $ast = q:to/./;
        (statements
          (my (ident "u")))
        .

    parses-to $program, $ast, "declaring without assigning";
}

{
    my $program = q:to/./;
        say(38 + 4);
        .

    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (+ (int 38) (int 4))))))
        .

    parses-to $program, $ast, "addition";
}

{
    my $program = q:to/./;
        my u = 0;
        u = u + 1;
        .

    my $ast = q:to/./;
        (statements
          (my (ident "u") (assign (ident "u") (int 0)))
          (stexpr (assign (ident "u") (+ (ident "u") (int 1)))))
        .

    parses-to $program, $ast, "assignment and addition";
}

{
    my $program = q:to/./;
        say("Jame" ~ "s Bond");
        .

    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (~ (str "Jame") (str "s Bond"))))))
        .

    parses-to $program, $ast, "string concatenation";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[1]);
        .

    my $ast = q:to/./;
        (statements
          (my (ident "ns") (assign (ident "ns") (array (str "Jim") (str "Bond"))))
          (stexpr (call (ident "say") (arguments (index (ident "ns") (int 1))))))
        .

    parses-to $program, $ast, "array indexing";
}

{
    my $program = q:to/./;
        my x = 1;
        x = 2;
        .

    my $ast = q:to/./;
        (statements
          (my (ident "x") (assign (ident "x") (int 1)))
          (stexpr (assign (ident "x") (int 2))))
        .

    parses-to $program, $ast, "assignment (outside of a declaration)";
}

{
    my $program = q:to/./;
        my i1 = 10;
        my i2 = 11;
        say(i1 == i2);
        .

    my $ast = q:to/./;
        (statements
          (my (ident "i1") (assign (ident "i1") (int 10)))
          (my (ident "i2") (assign (ident "i2") (int 11)))

          (stexpr (call (ident "say") (arguments (== (ident "i1") (ident "i2"))))))
        .

    parses-to $program, $ast, "equality";
}

{
    my $program = q:to/./;
        {
            say("immediate block");
        }
        .

    my $ast = q:to/./;
        (statements
          (stblock (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "immediate block"))))))))
        .

    parses-to $program, $ast, "immediate block";
}

{
    my $program = q:to/./;
        my b = -> name {
            say("Good evening, Mr " ~ name);
        };
        .

    my $ast = q:to/./;
        (statements
          (my (ident "b") (assign (ident "b") (block (parameters (ident "name")) (statements
            (stexpr (call (ident "say") (arguments (~ (str "Good evening, Mr ") (ident "name"))))))))))
        .

    parses-to $program, $ast, "block with parameter";
}

{
    my $program = q:to/./;
        my b = -> X, Y {
            say(X ~ Y);
        };
        .

    my $ast = q:to/./;
        (statements
          (my (ident "b") (assign (ident "b") (block (parameters (ident "X") (ident "Y")) (statements
            (stexpr (call (ident "say") (arguments (~ (ident "X") (ident "Y"))))))))))
        .

    parses-to $program, $ast, "block with two parameters";
}

{
    my $program = q:to/./;
        sub f() {
            say("sub");
        }
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "sub")))))))
        .

    parses-to $program, $ast, "sub";
}

{
    my $program = q:to/./;
        sub f(name) {
            say("Mr " ~ name);
        }
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters (ident "name")) (statements
            (stexpr (call (ident "say") (arguments (~ (str "Mr ") (ident "name"))))))))
        .

    parses-to $program, $ast, "sub with parameter";
}

{
    my $program = q:to/./;
        sub f(X, Y) {
            say(X ~ Y);
        }
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters (ident "X") (ident "Y")) (statements
            (stexpr (call (ident "say") (arguments (~ (ident "X") (ident "Y"))))))))
        .

    parses-to $program, $ast, "sub with two parameters";
}

{
    my $program = q:to/./;
        sub f() {
            return 7;
        }
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (return (int 7)))))
        .

    parses-to $program, $ast, "return statement";
}

{
    my $program = q:to/./;
        sub f() {
            return;
        }
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (return))))
        .

    parses-to $program, $ast, "empty return statement";
}

{
    my $program = q:to/./;
        sub f() {
            say("OH HAI");
        }
        sub g() {
            return { f(); };
        }
        g()();
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "OH HAI"))))))
          (sub (ident "g") (parameters) (statements
            (return (block (parameters) (statements
              (stexpr (call (ident "f") (arguments))))))))
          (stexpr (call (call (ident "g") (arguments)) (arguments))))
        .

    parses-to $program, $ast, "call to non-identifier";
}

{
    my $program = q:to/./;
        if "James" {
            say("oh wow, if statement");
        }
        .

    my $ast = q:to/./;
        (statements
          (if (str "James") (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "oh wow, if statement"))))))))
        .

    parses-to $program, $ast, "if statement";
}

{
    my $program = q:to/./;
        for [1, 2] {
            say("i");
        }
        .

    my $ast = q:to/./;
        (statements
          (for (array (int 1) (int 2)) (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "i"))))))))
        .

    parses-to $program, $ast, "for statement";
}

{
    my $program = q:to/./;
        for [1, 2] -> i {
            say(i);
        }
        .

    my $ast = q:to/./;
        (statements
          (for (array (int 1) (int 2)) (block (parameters (ident "i")) (statements
            (stexpr (call (ident "say") (arguments (ident "i"))))))))
        .

    parses-to $program, $ast, "for statement with one parameter";
}

{
    my $program = q:to/./;
        for [1, 2, 3, 4] -> i, j {
            say(i);
            say(j);
        }
        .

    my $ast = q:to/./;
        (statements
          (for (array (int 1) (int 2) (int 3) (int 4)) (block (parameters (ident "i") (ident "j")) (statements
            (stexpr (call (ident "say") (arguments (ident "i"))))
            (stexpr (call (ident "say") (arguments (ident "j"))))))))
        .

    parses-to $program, $ast, "for statement with two parameters";
}

{
    my $program = q:to/./;
        my u;
        while u {
            say(u);
        }
        .

    my $ast = q:to/./;
        (statements
          (my (ident "u"))
          (while (ident "u") (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (ident "u"))))))))
        .

    parses-to $program, $ast, "while statement";
}

done;
