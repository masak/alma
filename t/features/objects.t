use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my q = new Q::Identifier { name: "foo" };

        say(q.name);
        .

    outputs
        $program,
        qq[foo\n],
        "object literal syntax prefixed by type";
}

{
    my $program = q:to/./;
        my q = new Q::Identifier { dunnexist: "foo" };
        .

    parse-error
        $program,
        X::Property::NotDeclared,
        "the object property doesn't exist on that type";
}

{
    my $program = q:to/./;
        my q = new Q::Identifier { name: "foo" };

        say(type(q));
        .

    outputs
        $program,
        qq[<type Q::Identifier>\n],
        "an object literal is of the declared type";
}

{
    my $program = q:to/./;
        my i = new Int { value: 7 };
        my s = new Str { value: "Bond" };
        my a = new Array { value: [0, 0, 7] };

        say(i == 7);
        say(s == "Bond");
        say(a == [0, 0, 7]);
        .

    outputs
        $program,
        qq[True\nTrue\nTrue\n],
        "can create normal objects using typed object literals";
}

{
    my $program = q:to/./;
        my q = new Q::Identifier {};
        .

    parse-error
        $program,
        X::Property::Required,
        "need to specify required properties on objects (#87)";
}

done-testing;
