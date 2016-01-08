use v6;
use Test;
use _007::Test;

{
    my @exprs = «
        '{}'  '(object (identifier "Object") (propertylist))'
        '{"a": 1}' '(object (identifier "Object") (propertylist (property "a" (int 1))))'
        '{a}' '(object (identifier "Object") (propertylist (property "a" (identifier "a"))))'
        '{a : 1}' '(object (identifier "Object") (propertylist (property "a" (int 1))))'
        '{ a: 1}' '(object (identifier "Object") (propertylist (property "a" (int 1))))'
        '{a: 1 }' '(object (identifier "Object") (propertylist (property "a" (int 1))))'
        '{a: 1}' '(object (identifier "Object") (propertylist (property "a" (int 1))))'
        '{a() {}}' '(object (identifier "Object") (propertylist
          (property "a" (sub (identifier "a") (block (parameterlist) (statementlist))))))'
        '{a(a, b) {}}' '(object (identifier "Object") (propertylist (property "a" (sub (identifier "a") (block
          (parameterlist (param (identifier "a")) (param (identifier "b"))) (statementlist))))))'
    »;

    for @exprs -> $expr, $frag {
        my $ast = qq[(statementlist (my (identifier "a")) (stexpr {$frag}))];

        parses-to "my a; ($expr)", $ast, $expr;
    }
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o")
            (object (identifier "Object") (propertylist (property "a" (int 1)))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist
            (postfix:<.> (identifier "o") (identifier "a"))))))
        .

    is-result $ast, "1\n", "can access an object's property (dot syntax)";
}

{
    my $ast = q:to/./;
        (statementlist
          (my (identifier "o")
            (object (identifier "Object") (propertylist (property "b" (int 7)))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist
            (postfix:<[]> (identifier "o") (str "b"))))))
        .

    is-result $ast, "7\n", "can access an object's property (brackets syntax)";
}

{
    my $ast = q:to/./;
          (statementlist
            (my (identifier "o") (object (identifier "Object") (propertylist)))
            (stexpr (postfix:<.> (identifier "o") (identifier "a"))))
        .

    is-error $ast, X::PropertyNotFound, "can't access non-existing property (dot syntax)";
}

{
    my $ast = q:to/./;
          (statementlist
           (stexpr (postfix:<.> (int 42) (identifier "a"))))
        .

    is-error $ast, X::PropertyNotFound, "can't access property on Val::Int (dot syntax)";
}

{
    my $ast = q:to/./;
          (statementlist
            (my (identifier "o") (object (identifier "Object") (propertylist
              (property "foo" (int 1))
              (property "foo" (int 2))))))
        .

    is-error
        $ast,
        X::Property::Duplicate,
        "can't have duplicate properties (I)";
}

{
    my $program = q:to/./;
        my o = { foo: 1, foo: 2 };
        .

    parse-error
        $program,
        X::Property::Duplicate,
        "can't have duplicate properties (II)";
}

{
    my $ast = q:to/./;
          (statementlist
            (my (identifier "o") (object (identifier "Object") (propertylist)))
            (stexpr (postfix:<[]> (identifier "o") (str "b"))))
        .

    is-error $ast, X::PropertyNotFound, "can't access non-existing property (brackets syntax)";
}

{
    my $program = q:to/./;
        my o = { james: "bond", bond: 7 };

        say(o.has("bond"));
        say(o.has("jimmy"));

        say(o.get("bond"));

        say(o.update({ bond: 8 }));

        say({ x: 1 }.extend({ y: 2 }));

        my n = o.id;
        say("id");
        .

    outputs
        $program,
        qq[1\n0\n7\n\{bond: 8, james: "bond"\}\n\{x: 1, y: 2\}\nid\n],
        "built-in pseudo-inherited methods on objects";
}

{
    my $program = q:to/./;
        my q = Q::Identifier { name: "foo" };

        say(q.name);
        .

    outputs
        $program,
        qq[foo\n],
        "object literal syntax prefixed by type";
}

{
    my $program = q:to/./;
        my q = Q::Identifier { dunnexist: "foo" };
        .

    parse-error
        $program,
        X::Property::NotDeclared,
        "the object property doesn't exist on that type";
}

{
    my $program = q:to/./;
        my q = Q::Identifier { name: "foo" };

        say(type(q));
        .

    outputs
        $program,
        qq[<type Q::Identifier>\n],
        "an object literal is of the declared type";
}

{
    my $program = q:to/./;
        my q = Object { foo: 42 };

        say(q.foo);
        .

    outputs
        $program,
        qq[42\n],
        "can create a Val::Object by explicitly naming 'Object'";
}

{
    my $program = q:to/./;
        my i = Int { value: 7 };
        my s = Str { value: "Bond" };
        my a = Array { elements: [0, 0, 7] };
        my n = None {};

        say(i == 7);
        say(s == "Bond");
        say(a == [0, 0, 7]);
        say(n == None);
        .

    outputs
        $program,
        qq[1\n1\n1\n1\n],
        "can create normal Val:: objects using typed object literals";
}

{
    my $program = q:to/./;
        my q = Q::Identifier {};
        .

    parse-error
        $program,
        X::Property::Required,
        "need to specify required properties on objects";
}

done-testing;
