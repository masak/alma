use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my n = 7
        .

    my $ast = q:to/./;
        (statements
          (my (ident "n") (assign (ident "n") (int 7))))
        .

    parses-to $program, $ast, "can skip the last semicolon";
}

{
    my $program = q:to/./;
        my s = "Bond
        ";
        .

    parse-error $program, X::String::Newline, "can't have a newline in a string";
}

{
    my $program = q:to/./;
        say     (
            38
        +
            4       )
                ;
        .

    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (+ (int 38) (int 4))))))
        .

    parses-to $program, $ast, "spaces are fine here and there";
}

{
    my $program = q:to/./;
        say("A" ~ "B" ~ "C" ~ "D");
        .

    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (~ (~ (~ (str "A") (str "B")) (str "C")) (str "D"))))))
        .

    parses-to $program, $ast, "concat works any number of times (and is left-associative)";
}

{
    my $program = q:to/./;
        my aaa = [[[1]]];
        say(aaa[0][0][0]);
        .

    my $ast = q:to/./;
        (statements
          (my (ident "aaa") (assign (ident "aaa") (array (array (array (int 1))))))
          (stexpr (call (ident "say") (arguments (index (index (index (ident "aaa") (int 0)) (int 0)) (int 0))))))
        .

    parses-to $program, $ast, "array indexing works any number of times";
}

{
    my $program = q:to/./;
        my x = 5;
        {
            say("inside");
        }
        x = 7;
        .

    my $ast = q:to/./;
        (statements
          (my (ident "x") (assign (ident "x") (int 5)))
          (stblock (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "inside")))))))
          (stexpr (assign (ident "x") (int 7))))
        .

    parses-to $program, $ast, "can have a statement after a block without a semicolon";
}

{
    my $program = q:to/./;
        y = 5;
        .

    parse-error $program, X::Undeclared, "undeclared variables are caught at compile time";
}

{
    my $program = q:to/./;
        {
            my y = 7;
            say(y);
        }
        y = 5;
        .

    parse-error $program, X::Undeclared, "it's undeclared in the outer scope even if you declare it in an inner scope";
}

{
    my $program = q:to/./;
        {
            say("immediate block")
        }
        .

    my $ast = q:to/./;
        (statements
          (stblock (block (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "immediate block"))))))))
        .

    parses-to $program, $ast, "can skip the last semicolon in a block, too";
}

{
    my $program = q:to/./;
        -> name {
            say("Good evening, Mr " ~ name);
        };
        .

    parse-error $program, X::PointyBlock::SinkContext, "a pointy block can not occur in sink context";
}

{
    my $program = q:to/./;
        sub f(X, Y, X) {
            say(X ~ Y);
        }
        .

    parse-error $program, X::Redeclaration, "cannot redeclare parameters in sub";
}

{
    my $program = q:to/./;
        my x;
        my x;
        .

    parse-error $program, X::Redeclaration, "cannot redeclare variable";
}

{
    my $program = q:to/./;
        my x;
        {
            x = 7;
            my x;
        }
        .

    parse-error $program, X::Redeclaration::Outer, "cannot first use outer and then declare inner variable";
}

{
    my $program = q:to/./;
        sub foo(x) {
            my x;
        }
        .

    parse-error $program, X::Redeclaration, "cannot redeclare variable that's already a parameter";
}

{
    my $program = q:to/./;
        if "James" -> s {
            say(s);
        }
        .

    my $ast = q:to/./;
        (statements
          (if (str "James") (block (parameters (ident "s")) (statements
            (stexpr (call (ident "say") (arguments (ident "s"))))))))
        .

    parses-to $program, $ast, "if statement with a pointy block";
}

{
    my $program = q:to/./;
        return
        .

    parse-error $program, X::ControlFlow::Return, "cannot return from outside of a sub";
}

{
    my $program = q:to/./;
        say("\"");
        .

    my $ast = q:to/./;
        (statements
          (stexpr (call (ident "say") (arguments (str "\"")))))
        .

    parses-to $program, $ast, "can escape quotes inside string";
}

{
    my $program = q:to/./;
        my n=7;
        .

    my $ast = q:to/./;
        (statements
          (my (ident "n") (assign (ident "n") (int 7))))
        .

    parses-to $program, $ast, "don't have to have spaces around '=' in declaration";
}

{
    my $program = q:to/./;
        my a = [1, 2];
        a[1] = 4;
        .

    parse-error $program, X::Immutable, "cannot assign to a non-identifier";
}

{
    my $program = q:to/./;
        sub f() {}
        my f;
        .

    parse-error $program, X::Redeclaration, "can't have a sub and a variable sharing a name";
}

{
    my $program = q:to/./;
        my f;
        {
            f = 3;
            sub f() {
            }
        }
        .

    parse-error $program, X::Redeclaration::Outer, "cannot first use outer and then declare inner sub";
}

{
    my $program = q:to/./;
        my f;
        {
            f = 3;
            macro f() {
            }
        }
        .

    parse-error $program, X::Redeclaration::Outer, "...same thing, but with an inner macro";
}

{
    my $program = q:to/./;
        my 5 = "five";
        .

    parse-error $program, X::Syntax::Missing, "an identifier can not start with a digit";
}

done;
