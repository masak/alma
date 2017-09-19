use v6;
use Test;
use _007::Test;

{
    my @exprs = «
        '{}'  '(dict (propertylist))'
        '{"a": 1}' '(dict (propertylist (property "a" (int 1))))'
        '{"a": 1 + 2}' '(dict (propertylist (property "a" (infix:+ (int 1) (int 2)))))'
        '{"a": 1,}' '(dict (propertylist (property "a" (int 1))))'
        '{a}' '(dict (propertylist (property "a" (identifier "a"))))'
        '{a : 1}' '(dict (propertylist (property "a" (int 1))))'
        '{ a: 1}' '(dict (propertylist (property "a" (int 1))))'
        '{a: 1 }' '(dict (propertylist (property "a" (int 1))))'
        '{a: 1}' '(dict (propertylist (property "a" (int 1))))'
        '{a: 1 + 2}' '(dict (propertylist (property "a" (infix:+ (int 1) (int 2)))))'
        '{a() {}}' '(dict (propertylist
          (property "a" (sub (identifier "a") (block (parameterlist) (statementlist))))))'
        '{a(a, b) {}}' '(dict (propertylist (property "a" (sub (identifier "a") (block
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
            (dict (propertylist (property "b" (int 7)))))
          (stexpr (postfix:() (identifier "say") (argumentlist
            (postfix:[] (identifier "o") (str "b"))))))
        .

    is-result $ast, "7\n", "can access an object's property (brackets syntax)";
}

{
    my $ast = q:to/./;
          (statementlist
            (my (identifier "o") (dict (propertylist
              (property "foo" (int 1))
              (property "foo" (int 2))))))
        .

    is-error
        $ast,
        X::Property::Duplicate,
        "can't have duplicate properties (#85) (I)";
}

{
    my $program = q:to/./;
        my o = { foo: 1, foo: 2 };
        .

    parse-error
        $program,
        X::Property::Duplicate,
        "can't have duplicate properties (#85) (II)";
}

{
    my $ast = q:to/./;
          (statementlist
            (my (identifier "o") (dict (propertylist)))
            (stexpr (postfix:[] (identifier "o") (str "b"))))
        .

    is-error $ast, X::Property::NotFound, "can't access non-existing property (brackets syntax)";
}

{
    my $program = q:to/./;
        f();
        my o = { say };
        sub f() { say("Mr. Bond") }
        .

    outputs
        $program,
        qq[Mr. Bond\n],
        "using the short-form property syntax doesn't accidentally introduce a scope (#150)";
}

done-testing;
