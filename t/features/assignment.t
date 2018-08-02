use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my a = [1, 2];
        a[1] = "Bond";
        say(a);
        .

    outputs $program, qq<[1, "Bond"]\n>, "can assign to an element of an array";
}

{
    outputs '
        my o = { foo: 42 };
        o["bar"] = "James";
        o.baz = "Bond";
        say(o);',

        qq!\{bar: "James", baz: "Bond", foo: 42\}\n!,

        "can assign to a property of an object";
}

done-testing;
