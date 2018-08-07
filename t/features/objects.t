use v6;
use Test;
use _007::Test;

{
    outputs 'say({})', qq[\{\}\n], "empty object";
    outputs 'say({ "a": 1 })', qq[\{a: 1\}\n], "quoted key, literal value";
    outputs 'say({ "a": 1 + 2 })', qq[\{a: 3\}\n], "quoted key, computed value";
    outputs 'my a = "bond"; say({ a })', qq[\{a: "bond"\}\n], "object property shorthand";
    outputs 'say({ a: 1 })', qq[\{a: 1\}\n], "unquoted key, literal value";
    outputs 'say({a: 1})', qq[\{a: 1\}\n], "no space before and after";
    outputs 'say({a: 1 + 2})', qq[\{a: 3\}\n], "unquoted key, computed value";
    outputs 'say({a() {}})', qq[\{a: <func a()>\}\n], "object method shorthand";
    outputs 'say({a(a, b) {}})', qq[\{a: <func a(a, b)>\}\n], "object method shorthand with parameters";
}

{
    my $program = q:to/./;
        my o = { a: 1 };
        say(o.a);
        .

    outputs $program, "1\n", "can access an object's property (dot syntax)";
}

{
    my $program = q:to/./;
        my o = { b: 7 };
        say(o["b"]);
        .

    outputs $program, "7\n", "can access an object's property (brackets syntax)";
}

{
    my $program = q:to/./;
        my o = {};
        say(o.a);
        .

    runtime-error $program,
        X::Property::NotFound,
        "can't access non-existing property (dot syntax)";
}

{
    my $program = q:to/./;
        42.a
        .

    runtime-error $program,
        X::Property::NotFound,
        "can't access property on Int (dot syntax)";
}

{
    my $program = q:to/./;
        my o = {};
        say(o["b"]);
        .

    runtime-error $program,
        X::Property::NotFound,
        "can't access non-existing property (brackets syntax)";
}

{
    my $program = q:to/./;
        my o = { foo: 1, foo: 2 };
        .

    parse-error
        $program,
        X::Property::Duplicate,
        "can't have duplicate properties (#85)";
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
        qq[True\nFalse\n7\n\{bond: 8, james: "bond"\}\n\{x: 1, y: 2\}\nid\n],
        "built-in pseudo-inherited methods on objects";
}

{
    my $program = q:to/./;
        my q = new Q.Identifier { name: "foo" };

        say(q.name);
        .

    outputs
        $program,
        qq[foo\n],
        "object literal syntax prefixed by type";
}

{
    my $program = q:to/./;
        my q = new Q.Identifier { dunnexist: "foo" };
        .

    parse-error
        $program,
        X::Property::NotDeclared,
        "the object property doesn't exist on that type";
}

{
    my $program = q:to/./;
        my q = new Q.Identifier { name: "foo" };

        say(type(q));
        .

    outputs
        $program,
        qq[<type Q.Identifier>\n],
        "an object literal is of the declared type";
}

{
    my $program = q:to/./;
        my q = new Object { foo: 42 };

        say(q.foo);
        .

    outputs
        $program,
        qq[42\n],
        "can create a Val::Object by explicitly naming 'Object'";
}

{
    my $program = q:to/./;
        my i = new Int { value: 7 };
        my s = new Str { value: "Bond" };
        my a = new Array { elements: [0, 0, 7] };

        say(i == 7);
        say(s == "Bond");
        say(a == [0, 0, 7]);
        .

    outputs
        $program,
        qq[True\nTrue\nTrue\n],
        "can create normal Val:: objects using typed object literals";
}

{
    my $program = q:to/./;
        my q = new Q.Identifier {};
        .

    parse-error
        $program,
        X::Property::Required,
        "need to specify required properties on objects (#87)";
}

{
    my $program = q:to/./;
        my obj = {
            meth() {
                return 007;
            }
        };

        say(obj.meth());
        .

    outputs $program, "7\n", "a `return` inside of a (short-form) method is fine";
}

{
    my $program = q:to/./;
        f();
        my o = { say };
        func f() { say("Mr. Bond") }
        .

    outputs
        $program,
        qq[Mr. Bond\n],
        "using the short-form property syntax doesn't accidentally introduce a scope (#150)";
}

done-testing;
