use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (int 1)))))
        .

    is-result $ast, "1\n", "say() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "abs") (arglist (prefix:<-> (int 1)))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "abs") (arglist (int 1)))))))
        .

    is-result $ast, "1\n1\n", "abs() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "min") (arglist (prefix:<-> (int 1)) (int 2))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "min") (arglist (int 2) (prefix:<-> (int 1))))))))
        .

    is-result $ast, "-1\n-1\n", "min() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "max") (arglist (prefix:<-> (int 1)) (int 2))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "max") (arglist (int 2) (prefix:<-> (int 1))))))))
        .

    is-result $ast, "2\n2\n", "max() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "chr") (arglist (int 97)))))))
        .

    is-result $ast, "a\n", "chr() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "ord") (arglist (str "a")))))))
        .

    is-result $ast, "97\n", "ord() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (postfix:<()> (ident "int") (arglist (str "6"))))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (postfix:<()> (ident "int") (arglist (str "-6")))))))))
        .

    is-result $ast, "Int\nInt\n", "int() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (postfix:<()> (ident "str") (arglist (int 6)))))))))
        .

    is-result $ast, "Str\n", "str() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "chars") (arglist (str "007")))))))
        .

    is-result $ast, "3\n", "chars() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "uc") (arglist (str "test")))))))
        .

    is-result $ast, "TEST\n", "uc() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "lc") (arglist (str "TEST")))))))
        .

    is-result $ast, "test\n", "lc() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "trim") (arglist (str "  test  ")))))))
        .

    is-result $ast, "test\n", "trim() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "elems") (arglist (array (int 1) (int 2))))))))
        .

    is-result $ast, "2\n", "elems() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "reversed") (arglist (array (int 1) (int 2))))))))
        .

    is-result $ast, "[2, 1]\n", "reversed() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "sorted") (arglist (array (int 2) (int 1))))))))
        .

    is-result $ast, "[1, 2]\n", "sorted() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "join") (arglist (array (int 1) (int 2)) (str "|")))))))
        .

    is-result $ast, "1|2\n", "join() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "split") (arglist (str "a|b") (str "|")))))))
        .

    is-result $ast, qq|["a", "b"]\n|, "split() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "index") (arglist (str "abc") (str "bc"))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "index") (arglist (str "abc") (str "a"))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "index") (arglist (str "abc") (str "d")))))))
        .

    is-result $ast, "1\n0\n-1\n", "index() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "substr") (arglist (str "abc") (int 0) (int 1))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "substr") (arglist (str "abc") (int 1))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "substr") (arglist (str "abc") (int 0) (int 5)))))))
        .

    is-result $ast, "a\nbc\nabc\n", "substr() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "charat") (arglist (str "abc") (int 0)))))))
        .

    is-result $ast, "a\n", "charat() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "charat") (arglist (str "abc") (int 3)))))))
        .

    is-error $ast, X::Subscript::TooLarge, "charat() dies";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist (ident "n")) (stmtlist
              (return (infix:<==> (ident "n") (int 2))))))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "filter") (arglist (ident "f") (array (int 1) (int 2) (int 3) (int 2))))))))
        .

    is-result $ast, "[2, 2]\n", "filter() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist (ident "n")) (stmtlist
              (return (infix:<+> (ident "n") (int 1))))))
          (my (ident "a") (array (int 1) (int 2) (int 3)))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "map") (arglist (ident "f") (ident "a"))))))
          (stexpr (postfix:<()> (ident "say") (arglist (ident "a")))))
        .

    is-result $ast, "[2, 3, 4]\n[1, 2, 3]\n", "map() works";
}

{
    my $program = q:to/./;
        my q = Q::Literal::Int { value: 7 };

        say(melt(q));
        .

    outputs
        $program,
        qq[7\n],
        "melt() on literal int";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "q")
            (object (ident "Q::Statement::My") (proplist
              (property "ident" (object (ident "Q::Identifier") (proplist
                (property "name" (str "agent")))))
              (property "expr" (str "James Bond")))))
          (stexpr (postfix:<()> (ident "melt") (arglist (ident "q")))))
        .

    is-error
        $ast,
        X::TypeCheck,
        "cannot melt() a statement";
}

{
    my $program = q:to/./;
        my x = "Bond";
        my q = Q::Identifier { name: "x" };

        say(melt(q));
        .

    outputs
        $program,
        qq[Bond\n],
        "melt() on a variable";
}

{
    my $program = q:to/./;
        sub foo() {
            my lookup = "hygienic";
            return Q::Identifier { name: "lookup" };
        }

        my lookup = "unhygienic";
        my ident = foo();
        say(melt(ident));
        .

    outputs
        $program,
        qq[unhygienic\n],
        "melted identifier lookup is unhygienic";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "n"))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (ident "n")))))))
        .

    is-result $ast, "None\n", "none type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "n") (int 7))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (ident "n")))))))
        .

    is-result $ast, "Int\n", "int type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "s") (str "Bond"))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (ident "s")))))))
        .

    is-result $ast, "Str\n", "str type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "a") (array (int 1) (int 2)))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (ident "a")))))))
        .

    is-result $ast, "Array\n", "array type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (sub (ident "f") (block (paramlist) (stmtlist)))
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (ident "f")))))))
        .

    is-result $ast, "Sub\n", "sub type() works";
}

{
    my $ast = q:to/./;
        (stmtlist
          (stexpr (postfix:<()> (ident "say") (arglist (postfix:<()> (ident "type") (arglist (ident "say")))))))
        .

    is-result $ast, "Sub\n", "builtin sub type() returns the same as ordinary sub";
}

done-testing;
