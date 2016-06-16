use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (prefix:<-> (int 1)) (identifier "abs")) (argumentlist)))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (int 1) (identifier "abs")) (argumentlist))))))
        .

    is-result $ast, "1\n1\n", "abs() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (int 97) (identifier "chr")) (argumentlist))))))
        .

    is-result $ast, "a\n", "chr() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "a") (identifier "ord")) (argumentlist))))))
        .

    is-result $ast, "97\n", "ord() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "007") (identifier "chars")) (argumentlist))))))
        .

    is-result $ast, "3\n", "chars() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "test") (identifier "uc")) (argumentlist))))))
        .

    is-result $ast, "TEST\n", "uc() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "TEST") (identifier "lc")) (argumentlist))))))
        .

    is-result $ast, "test\n", "lc() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "  test  ") (identifier "trim")) (argumentlist))))))
        .

    is-result $ast, "test\n", "trim() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (array (int 1) (int 2)) (identifier "elems")) (argumentlist))))))
        .

    is-result $ast, "2\n", "elems() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (array (int 1) (int 2)) (identifier "reverse")) (argumentlist))))))
        .

    is-result $ast, "[2, 1]\n", "reverse() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (array (int 2) (int 1)) (identifier "sort")) (argumentlist))))))
        .

    is-result $ast, "[1, 2]\n", "sort() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()>
            (postfix:<.> (array (int 1) (int 2)) (identifier "concat"))
            (argumentlist (array (int 3) (int 4))))))))
        .

    is-result $ast, "[1, 2, 3, 4]\n", "concat() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()>
            (postfix:<.> (array (int 1) (int 2)) (identifier "join"))
            (argumentlist (str "|")))))))
        .

    is-result $ast, "1|2\n", "join() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()>
            (postfix:<.> (str "a|b") (identifier "split"))
            (argumentlist (str "|")))))))
        .

    is-result $ast, qq|["a", "b"]\n|, "split() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "index")) (argumentlist (str "bc"))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "index")) (argumentlist (str "a"))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "index")) (argumentlist (str "d")))))))
        .

    is-result $ast, "1\n0\n-1\n", "index() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "substr")) (argumentlist (int 0) (int 1))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "substr")) (argumentlist (int 0) (int 5)))))))
        .

    is-result $ast, "a\nabc\n", "substr() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "prefix")) (argumentlist (int 1)))))))
        .

    is-result $ast, "a\n", "prefix() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "suffix")) (argumentlist (int 1)))))))
        .

    is-result $ast, "bc\n", "suffix() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "charat")) (argumentlist (int 0)))))))
        .

    is-result $ast, "a\n", "charat() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (str "abc") (identifier "charat")) (argumentlist (int 3)))))))
        .

    is-error $ast, X::Subscript::TooLarge, "charat() dies";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist (param (identifier "n"))) (statementlist
              (return (infix:<==> (identifier "n") (int 2))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (array (int 1) (int 2) (int 3) (int 2)) (identifier "filter")) (argumentlist (identifier "f")))))))
        .

    is-result $ast, "[2, 2]\n", "filter() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist (param (identifier "n"))) (statementlist
              (return (infix:<+> (identifier "n") (int 1))))))
          (my (identifier "a") (array (int 1) (int 2) (int 3)))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (identifier "a") (identifier "map")) (argumentlist (identifier "f"))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a")))))
        .

    is-result $ast, "[2, 3, 4]\n[1, 2, 3]\n", "map() works";
}

{
    my $program = q:to/./;
        macro so_hygienic() {
            my x = "yay, clean!";
            return quasi {
                say(x);
            };
        }

        macro so_unhygienic() {
            my x = "something is implemented wrong";
            return quasi {
                say(x)
            }.detach();
        }

        my x = "that's gross!";
        so_hygienic();    # yay, clean!
        so_unhygienic();  # that's gross!
        .

    outputs $program, "yay, clean!\nthat's gross!\n",
        "detaching a qtree makes its identifiers unhygienic (#62)";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2)))
          (stexpr (postfix:<()> (postfix:<.> (identifier "a") (identifier "push")) (argumentlist (int 3))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a")))))
        .

    is-result $ast, "[1, 2, 3]\n", "Array.push() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2) (int 5)))
          (my (identifier "x") (postfix:<()> (postfix:<.> (identifier "a") (identifier "pop")) (argumentlist)))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "x"))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a")))))
        .

    is-result $ast, "5\n[1, 2]\n", "Array.pop() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array))
          (stexpr (postfix:<()> (postfix:<.> (identifier "a") (identifier "pop")) (argumentlist))))
        .

    is-error $ast, X::Cannot::Empty, "cannot Array.pop() an empty array";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2)))
          (stexpr (postfix:<()> (postfix:<.> (identifier "a") (identifier "unshift")) (argumentlist (int 3))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a")))))
        .

    is-result $ast, "[3, 1, 2]\n", "Array.unshift() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2) (int 5)))
          (my (identifier "x") (postfix:<()> (postfix:<.> (identifier "a") (identifier "shift")) (argumentlist)))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "x"))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a")))))
        .

    is-result $ast, "1\n[2, 5]\n", "Array.shift() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array))
          (stexpr (postfix:<()> (postfix:<.> (identifier "a") (identifier "shift")) (argumentlist))))
        .

    is-error $ast, X::Cannot::Empty, "cannot Array.shift() an empty array";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (str "007"))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (identifier "a") (identifier "contains")) (argumentlist (str "07"))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (postfix:<.> (identifier "a") (identifier "contains")) (argumentlist (str "8")))))))
        .

    is-result $ast, "1\n0\n", "String.contains() works";
}

done-testing;

