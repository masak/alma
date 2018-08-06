use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say((-1).abs());
        say(1.abs());
        .

    outputs $program, "1\n1\n", "abs() returns the absolute value";
}

{
    my $program = q:to/./;
        say(97.chr());
        .

    outputs $program, "a\n", "chr() returns the character corresponding to a codepoint";
}

{
    my $program = q:to/./;
        say("a".ord());
        .

    outputs $program, "97\n", "ord() returns the codepoint corresponding to a character";
}

{
    my $program = q:to/./;
        say("007".chars());
        .

    outputs $program, "3\n", "chars() returns the length (number of characters) of a string";
}

{
    my $program = q:to/./;
        say("test".uc());
        .

    outputs $program, "TEST\n", "uc() upper-cases a string";
}

{
    my $program = q:to/./;
        say("TEST".lc());
        .

    outputs $program, "test\n", "lc() lower-cases a string";
}

{
    my $program = q:to/./;
        say("  test  ".trim());
        .

    outputs $program, "test\n", "trim() removes leading and trailing whitespace";
}

{
    my $program = q:to/./;
        say([1, 2].size());
        .

    outputs $program, "2\n", "size() returns the size of an Array";
}

{
    my $program = q:to/./;
        say({}.size());
        .

    outputs $program, "0\n", "size() returns the size of an Object";
}

{
    my $program = q:to/./;
        say([1, 2].reverse());
        .

    outputs $program, "[2, 1]\n", "reverse() returns an Array, reversed";
}

{
    my $program = q:to/./;
        say([2, 1].sort());
        .

    outputs $program, "[1, 2]\n", "sort() returns an Array, sorted";
}

{
    my $program = q:to/./;
        [2, 1, "A"].sort();
        .

    runtime-error
        $program,
        X::TypeCheck::HeterogeneousArray,
        "sort() on heterogeneous arrays should not work";
}

{
    my $program = q:to/./;
        say([1, 2].concat([3, 4]));
        .

    outputs $program, "[1, 2, 3, 4]\n", "concat() returns two arrays joined into one";
}

{
    my $program = q:to/./;
        say([1, 2].join("|"));
        .

    outputs $program, "1|2\n", "join() returns the elements of an array with a separator";
}

{
    my $program = q:to/./;
        say("a|b".split("|"));
        .

    outputs $program, qq|["a", "b"]\n|, "split() splits a string into elements separated by a separator";
}

{
    my $program = q:to/./;
        say("abc".index("bc"));
        say("abc".index("a"));
        say("abc".index("d"));
        .

    outputs $program, "1\n0\n-1\n", "index() returns the index of the first occurrence of a substring, if any";
}

{
    my $program = q:to/./;
        say("abc".substr(0, 1));
        say("abc".substr(0, 5));
        .

    outputs $program, "a\nabc\n", "substr() picks out a substring of a string";
}

{
    my $program = q:to/./;
        say("abc".prefix(1));
        .

    outputs $program, "a\n", "prefix() picks out a prefix of a string";
}

{
    my $program = q:to/./;
        say("abc".suffix(1));
        .

    outputs $program, "bc\n", "suffix() picks out a suffix of a string";
}

{
    my $program = q:to/./;
        say("abc".charat(0));
        .

    outputs $program, "a\n", "charat() picks a character out of a string";
}

{
    my $program = q:to/./;
        "abc".charat(3);
        .

    runtime-error
        $program,
        X::Subscript::TooLarge,
        "charat() can be out of range";
}

{
    my $program = q:to/./;
        func f(n) { n == 2 }
        say([1, 2, 3, 2].filter(f));
        .

    outputs $program, "[2, 2]\n", "filter() returns the elements from an array matching a predicate";
}

{
    my $program = q:to/./;
        func f(n) { n + 1 }
        my a = [1, 2, 3];
        say(a.map(f));
        say(a);
        .

    outputs $program, "[2, 3, 4]\n[1, 2, 3]\n", "map() returns the elements from an array, transformed";
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
    my $program = q:to/./;
        my a = [1, 2];
        a.push(3);
        say(a);
        .

    outputs $program, "[1, 2, 3]\n", "push() adds an element to the end of an array";
}

{
    my $program = q:to/./;
        my a = [1, 2, 5];
        my x = a.pop();
        say(x);
        say(a);
        .

    outputs $program, "5\n[1, 2]\n", "pop() removes an element from the end of an array";
}

{
    my $program = q:to/./;
        my a = [];
        a.pop();
        .

    runtime-error
        $program,
        X::Cannot::Empty,
        "cannot Array.pop() and empty array";
}

{
    my $program = q:to/./;
        my a = [1, 2];
        a.unshift(3);
        say(a);
        .

    outputs $program, "[3, 1, 2]\n", "unshift() adds an element to the beginning of an array";
}

{
    my $program = q:to/./;
        my a = [1, 2, 5];
        my x = a.shift();
        say(x);
        say(a);
        .

    outputs $program, "1\n[2, 5]\n", "shift() removes an element from the beginning of an array";
}

{
    my $program = q:to/./;
        my a = [];
        a.shift();
        .

    runtime-error
        $program,
        X::Cannot::Empty,
        "cannot Array.shift() and empty array";
}

{
    my $program = q:to/./;
        my a = "007";
        say(a.contains("07"));
        say(a.contains("8"));
        .

    outputs $program, "True\nFalse\n", "contains() returns whether a string contains another";
}

{
    my $program = q:to/./;
        say(Object.create([["foo", 42]]));
        .

    outputs $program, qq[\{foo: 42\}\n], "Type.create() method to create an Object";
}

{
    my $program = q:to/./;
        say(Int.create([["value", 7]]));
        .

    outputs $program, qq[7\n], "Type.create() method to create an Int";
}

{
    my $program = q:to/./;
        say(Str.create([["value", "no, Mr Bond, I expect you to die"]]));
        .

    outputs $program, qq[no, Mr Bond, I expect you to die\n], "Type.create() method to create a Str";
}

{
    my $program = q:to/./;
        say(Array.create([["elements", [0, 0, 7]]]));
        .

    outputs $program, qq<[0, 0, 7]\n>, "Type.create() method to create an Array";
}

{
    my $program = q:to/./;
        say(Tuple.create([["elements", (0, 0, 7)]]));
        .

    outputs $program, qq<(0, 0, 7)\n>, "Type.create() method to create a Tuple";
}

{
    my $program = q:to/./;
        say(Type.create([["name", "MyType"]]));
        .

    outputs $program, qq[<type MyType>\n], "Type.create() method to create a Type";
}

{
    my $program = q:to/./;
        say(Q.Identifier.create([["name", "Steve"]]));
        .

    outputs $program, qq[Q.Identifier "Steve"\n], "Type.create() method to create a Q::Identifier";
}

{
    my $program = q:to/./;
        say(NoneType.create([]));
        .

    runtime-error $program, X::Uninstantiable, "can't instantiate a NoneType";
}

{
    my $program = q:to/./;
        say(Bool.create([["value", False]]));
        .

    runtime-error $program, X::Uninstantiable, "can't instantiate a Bool";
}

done-testing;

