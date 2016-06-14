use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (int 1)))))
        .

    is-result $ast, "1\n", "say() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "min") (argumentlist (prefix:<-> (int 1)) (int 2))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "min") (argumentlist (int 2) (prefix:<-> (int 1))))))))
        .

    is-result $ast, "-1\n-1\n", "min() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "max") (argumentlist (prefix:<-> (int 1)) (int 2))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "max") (argumentlist (int 2) (prefix:<-> (int 1))))))))
        .

    is-result $ast, "2\n2\n", "max() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "n"))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (identifier "n")))))))
        .

    is-result $ast, "<type None>\n", "none type() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "n") (int 7))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (identifier "n")))))))
        .

    is-result $ast, "<type Int>\n", "int type() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "s") (str "Bond"))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (identifier "s")))))))
        .

    is-result $ast, "<type Str>\n", "str type() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2)))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (identifier "a")))))))
        .

    is-result $ast, "<type Array>\n", "array type() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stsub (identifier "f") (block (parameterlist) (statementlist)))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (identifier "f")))))))
        .

    is-result $ast, "<type Sub>\n", "sub type() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (identifier "say")))))))
        .

    is-result $ast, "<type Sub>\n", "builtin sub type() returns the same as ordinary sub";
}

{
     my $ast = q:to/./;
         (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (postfix:<()> (identifier "int") (argumentlist (str "6"))))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (postfix:<()> (identifier "int") (argumentlist (str "-6")))))))))
        .

    is-result $ast, "<type Int>\n<type Int>\n", "int() works";
}

{
    my $ast = q:to/./;
        (statementlist
          (stexpr (postfix:<()> (identifier "say") (argumentlist (postfix:<()> (identifier "type") (argumentlist (postfix:<()> (identifier "str") (argumentlist (int 6)))))))))
        .

    is-result $ast, "<type Str>\n", "str() works";
}

done-testing;
