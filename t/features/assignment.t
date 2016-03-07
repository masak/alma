use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "a") (array (int 1) (int 2)))
          (stexpr (infix:<=> (postfix:<[]> (identifier "a") (int 1)) (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "a")))))
        .

    is-result $ast, "[1, \"Bond\"]\n", "can assign to an element of an array (I)";
}

{
    outputs '
        my a = [1, 2];
        a[1] = "Bond";
        say(a);',

        qq![1, "Bond"]\n!,

        "can assign to an element of an array (II)";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o") (object (identifier "Object") (propertylist (property "foo" (int 42)))))
          (stexpr (infix:<=> (postfix:<[]> (identifier "o") (str "bar")) (str "James")))
          (stexpr (infix:<=> (postfix:<.> (identifier "o") (identifier "baz")) (str "Bond")))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (identifier "o")))))
        .

    is-result $ast,
        "\{bar: \"James\", baz: \"Bond\", foo: 42\}\n",
        "can assign to a property of an object (I)";
}

{
    outputs '
        my o = { foo: 42 };
        o["bar"] = "James";
        o.baz = "Bond";
        say(o);',

        qq!\{bar: "James", baz: "Bond", foo: 42\}\n!,

        "can assign to a property of an object (II)";
}

done-testing;
