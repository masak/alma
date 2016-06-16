use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my n = None;
        .

    my $ast = q:to/./;
        (statementlist
          (my (identifier "n") (none)))
        .

    parses-to $program, $ast, "assigning a none (#19)";
}

{
    my $program = q:to/./;
        my n = 7;
        .

    my $ast = q:to/./;
        (statementlist
          (my (identifier "n") (int 7)))
        .

    parses-to $program, $ast, "assigning an int";
}

{
    my $program = q:to/./;
        my s = "Bond";
        .

    my $ast = q:to/./;
        (statementlist
          (my (identifier "s") (str "Bond")))
        .

    parses-to $program, $ast, "assigning a str";
}

{
    my $program = q:to/./;
        my a = [1, 2];
        .

    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2))))
        .

    parses-to $program, $ast, "assigning an array";
}

{
    my $program = q:to/./;
        [1, 2, 3,];
        .

    my $ast = q:to/./;
        (statementlist
          (stexpr (array (int 1) (int 2) (int 3))))
        .

    parses-to $program, $ast, "trailing comma in array is fine (#36)";
}

{
    my $program = q:to/./;
        [1, 2, 3, ];
        .

    my $ast = q:to/./;
        (statementlist
          (stexpr (array (int 1) (int 2) (int 3))))
        .

    parses-to $program, $ast, "whitespace after trailing comma in array is fine (#138)";
}

{
    my $program = q:to/./;
        [ ];
        .

    my $ast = q:to/./;
        (statementlist
          (stexpr (array)))
        .

    parses-to $program, $ast, "(only) whitespace inside array is fine (#138)";
}

{
    my $program = q:to/./;
        my u;
        .

    my $ast = q:to/./;
        (statementlist
          (my (identifier "u")))
        .

    parses-to $program, $ast, "declaring without assigning";
}

{
    my $program = q:to/./;
        say(38 + 4);
        .

    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<+> (int 38) (int 4))))))
        .

    parses-to $program, $ast, "addition";
}

{
    my $program = q:to/./;
        my u = 0;
        u = u + 1;
        .

    my $ast = q:to/./;
        (statementlist
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
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<~> (str "Jame") (str "s Bond"))))))
        .

    parses-to $program, $ast, "string concatenation";
}

{
    my $program = q:to/./;
        my ns = ["Jim", "Bond"];
        say(ns[1]);
        .

    my $ast = q:to/./;
        (statementlist
          (my (identifier "ns") (array (str "Jim") (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<[]> (identifier "ns") (int 1))))))
        .

    parses-to $program, $ast, "array indexing";
}

{
    my $program = q:to/./;
        my x = 1;
        x = 2;
        .

    my $ast = q:to/./;
        (statementlist
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
        (statementlist
          (my (identifier "i1") (int 10))
          (my (identifier "i2") (int 11))

          (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<==> (identifier "i1") (identifier "i2"))))))
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
        (statementlist
          (stblock (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "immediate block"))))))))
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
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "sub"))))))))
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
        (statementlist
          (stsub (identifier "f") (block (parameterlist (param (identifier "name"))) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<~> (str "Mr ") (identifier "name")))))))))
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
        (statementlist
          (stsub (identifier "f") (block (parameterlist (param (identifier "X")) (param (identifier "Y"))) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (infix:<~> (identifier "X") (identifier "Y")))))))))
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
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
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
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
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
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "OH HAI")))))))
          (stsub (identifier "g") (block (parameterlist) (statementlist
            (stsub (identifier "h") (block (parameterlist) (statementlist
              (stexpr (postfix:<()> (identifier "f") (argumentlist))))))
            (return (identifier "h")))))
          (stexpr (postfix:<()> (postfix:<()> (identifier "g") (argumentlist)) (argumentlist))))
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
        (statementlist
          (if (str "James") (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "oh wow, if statement"))))))))
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
        (statementlist
          (for (array (int 1) (int 2)) (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "i"))))))))
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
        (statementlist
          (for (array (int 1) (int 2)) (block (parameterlist (param (identifier "i"))) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "i"))))))))
        .

    parses-to $program, $ast, "for statement with one parameter";
}

{
    my $program = q:to/./;
        my u;
        while u {
            say(u);
        }
        .

    my $ast = q:to/./;
        (statementlist
          (my (identifier "u"))
          (while (identifier "u") (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "u"))))))))
        .

    parses-to $program, $ast, "while statement";
}

done-testing;
