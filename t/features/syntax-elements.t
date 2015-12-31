use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my n = None;
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "n") (none)))
        .

    parses-to $program, $ast, "assigning a none";
}

{
    my $program = q:to/./;
        my n = 7;
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "n") (int 7)))
        .

    parses-to $program, $ast, "assigning an int";
}

{
    my $program = q:to/./;
        my s = "Bond";
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "s") (str "Bond")))
        .

    parses-to $program, $ast, "assigning a str";
}

{
    my $program = q:to/./;
        my a = [1, 2];
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "a") (array (int 1) (int 2))))
        .

    parses-to $program, $ast, "assigning an array";
}

{
    my $program = q:to/./;
        [1, 2, 3,];
        .

    my $ast = q:to/./;
        (stmtlist
          (stexpr (array (int 1) (int 2) (int 3))))
        .

    parses-to $program, $ast, "trailing comma in array is fine";
}

{
    my $program = q:to/./;
        my u;
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "u")))
        .

    parses-to $program, $ast, "declaring without assigning";
}

{
    my $program = q:to/./;
        say(38 + 4);
        .

    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (identifier "say") (arglist (infix:<+> (int 38) (int 4))))))
        .

    parses-to $program, $ast, "addition";
}

{
    my $program = q:to/./;
        my u = 0;
        u = u + 1;
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "u") (int 0))
          (stexpr (infix:<=> (identifier "u") (infix:<+> (identifier "u") (int 1)))))
        .

    parses-to $program, $ast, "assignment and addition";
}

{
    my $program = q:to/./;
        say("Jame" ~ "s Bond");
        .

    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (identifier "say") (arglist (infix:<~> (str "Jame") (str "s Bond"))))))
        .

    parses-to $program, $ast, "string concatenation";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[1]);
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (arglist (postfix:<[]> (identifier "ns") (int 1))))))
        .

    parses-to $program, $ast, "array indexing";
}

{
    my $program = q:to/./;
        my x = 1;
        x = 2;
        .

    my $ast = q:to/./;
        (stmtlist
          (my (identifier "x") (int 1))
          (stexpr (infix:<=> (identifier "x") (int 2))))
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
        (stmtlist
          (my (identifier "i1") (int 10))
          (my (identifier "i2") (int 11))

          (stexpr (postfix:<()> (identifier "say") (arglist (infix:<==> (identifier "i1") (identifier "i2"))))))
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
        (stmtlist
          (stblock (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "immediate block"))))))))
        .

    parses-to $program, $ast, "immediate block";
}

{
    my $program = q:to/./;
        sub f() {
            say("sub");
        }
        .

    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "sub"))))))))
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
        (stmtlist
          (sub (identifier "f") (block (parameterlist (param (identifier "name"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (infix:<~> (str "Mr ") (identifier "name")))))))))
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
        (stmtlist
          (sub (identifier "f") (block (parameterlist (param (identifier "X")) (param (identifier "Y"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (infix:<~> (identifier "X") (identifier "Y")))))))))
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
        (stmtlist
          (sub (identifier "f") (block (parameterlist) (stmtlist
            (return (int 7))))))
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
        (stmtlist
          (sub (identifier "f") (block (parameterlist) (stmtlist
            (return)))))
        .

    parses-to $program, $ast, "empty return statement";
}

{
    my $program = q:to/./;
        sub f() {
            say("OH HAI");
        }
        sub g() {
            sub h() { f() };
            return h;
        }
        g()();
        .

    my $ast = q:to/./;
        (stmtlist
          (sub (identifier "f") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "OH HAI")))))))
          (sub (identifier "g") (block (parameterlist) (stmtlist
            (sub (identifier "h") (block (parameterlist) (stmtlist
              (stexpr (postfix:<()> (identifier "f") (arglist))))))
            (return (identifier "h")))))
          (stexpr (postfix:<()> (postfix:<()> (identifier "g") (arglist)) (arglist))))
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
        (stmtlist
          (if (str "James") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "oh wow, if statement"))))))))
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
        (stmtlist
          (for (array (int 1) (int 2)) (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (str "i"))))))))
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
        (stmtlist
          (for (array (int 1) (int 2)) (block (parameterlist (param (identifier "i"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "i"))))))))
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
        (stmtlist
          (for (array (int 1) (int 2) (int 3) (int 4)) (block (parameterlist (param (identifier "i")) (param (identifier "j"))) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "i"))))
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "j"))))))))
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
        (stmtlist
          (my (identifier "u"))
          (while (identifier "u") (block (parameterlist) (stmtlist
            (stexpr (postfix:<()> (identifier "say") (arglist (identifier "u"))))))))
        .

    parses-to $program, $ast, "while statement";
}

done-testing;
