use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        func infix:<n>(left, right) {
            return 20;
        }

        say(4 * 5);
        .

    outputs $program, "20\n", "using an operator after defining it works";
}

{
    my $program = q:to/./;
        say(4 n 5);
        .

    parse-error $program, X::AdHoc, "infix:n should not be defined unless we define it";
}

{
    my $program = q:to/./;
        {
            func infix:<n>(left, right) {
                return 7;
            }
        }
        say(4 n 5);
        .

    parse-error $program, X::AdHoc, "infix:n should not be usable outside of its scope";
}

{
    my $program = q:to/./;
        func infix:<+>(left, right) {
            return 14;
        }

        say(1 + 4);
        .

    outputs $program, "14\n", "can override a built-in operator";
}

{
    my $program = q:to/./;
        func infix:<~~>(left, right) {
            return "wrong";
        }

        func infix:<~~~>(left, right) {
            return "right";
        }

        say(4 ~~~ 5);
        .

    outputs $program, "right\n", "longest token wins, not first";
}

{
    my $program = q:to/./;
        func infix:<***>(left, right) {
            return "right";
        }

        func infix:<**>(left, right) {
            return "wrong";
        }

        say(4 *** 5);
        .

    outputs $program, "right\n", "longest token wins, not last";
}

{
    my $program = q:to/./;
        func infix:<!>(left, right) {
            say(left ~ " " ~ right);
        }

        BEGIN { "OH" ! "HAI" }
        .

    outputs $program, "OH HAI\n", "defined operators work from within BEGIN blocks";
}

{
    my $program = q:to/./;
        func infix:<!>(left, right) {
            say(left ~ " " ~ right);
        }

        BEGIN "OH" ! "HAI";
        .

    outputs $program, "OH HAI\n", "defined operators work from within BEGIN statements";
}

{
    my $program = q:to/./;
        func infix:<*!>(left, right) {
            return 10;
        }

        say(1 + 5 *! 5);
        .

    outputs $program, "11\n", "new operators bind maximally tightly";
}

{
    my $program = q:to/./;
        @looser(infix:<+>)
        func infix:<~?>(left, right) {
            return 6;
        }

        say(1 + 9 ~? 12);
        .

    outputs $program, "6\n", "can specify decorator to bind loose";
}

{
    my $program = q:to/./;
        @tighter(infix:<+>)
        func infix:<~?>(left, right) {
            return 6;
        }

        say(1 + 9 ~? 12);
        .

    outputs $program, "7\n", "can specify decorator to bind tight";
}

{
    my $program = q:to/./;
        func infix:<*>(left, right) {
            return 18;
        }

        @tighter(infix:<+>)
        func infix:<~@>(left, right) {
            return 30;
        }

        say(1 ~@ 2 * 9);
        .

    outputs $program, "30\n", "the new op is tighter than +, but not *";
}

{
    my $program = q:to/./;
        @tighter(infix:<+>)
        @looser(infix:<+>)
        func infix:<!?!>(left, right) {
        }
        .

    parse-error $program, X::Decorator::Conflict, "can't have both tighter and looser decorators";
}

{
    my $program = q:to/./;
        @equiv(infix:<+>)
        @equiv(infix:<*>)
        func infix:<!?!>(left, right) {
        }
        .

    parse-error $program, X::Decorator::Duplicate, "can't use the same decorator more than once";
}


{
    my $program = q:to/./;
        func infix:<@>(left, right) {
            return "@";
        }

        @equiv(infix:<@>)
        func infix:<!>(left, right) {
            return "!";
        }

        say(10 @ 2 ! 3);
        say(30 ! 2 @ 14);
        .

    outputs $program, "!\n@\n", "can specify decorator to bind equiv";
}

{
    my $program = q:to/./;
        @tighter(infix:<+>)
        @equiv(infix:<+>)
        func infix:<!?!>(left, right) {
        }
        .

    parse-error $program, X::Decorator::Conflict, "can't have both tighter and equiv decorators";
}

{
    my $program = q:to/./;
        @looser(infix:<+>)
        @equiv(infix:<+>)
        func infix:<!++>(left, right) {
        }
        .

    parse-error $program, X::Decorator::Conflict, "can't have both looser and equiv decorators";
}

{
    my $program = q:to/./;
        @assoc("right")
        func infix:<@>(left, right) {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("A" @ "B" @ "C");
        .

    outputs $program, "(A, (B, C))\n", "associativity means we can control the shape of the expr tree";
}

{
    my $program = q:to/./;
        @assoc("left")
        func infix:<%>(left, right) {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("A" % "B" % "C");
        .

    outputs $program, "((A, B), C)\n", "left associativity can be specified";
}

{
    my $program = q:to/./;
        func infix:</>(left, right) {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("x" / "y" / "z");
        .

    outputs $program, "((x, y), z)\n", "left associativity is the default";
}

{
    my $program = q:to/./;
        @assoc("non")
        func infix:<!>(left, right) {
            return "oh, James";
        }

        say(0 ! 7);
        .

    outputs $program, "oh, James\n", "can define an operator to be non-associative";
}

{
    my $program = q:to/./;
        @assoc("non")
        func infix:<!>(left, right) {
            return "oh, James";
        }

        say(0 ! 0 ! 7);
        .

    parse-error $program, X::Op::Nonassociative, "a non-associative operator can't associate";
}

{
    my $program = q:to/./;
        @assoc("salamander")
        func infix:<&-&>(left, right) {
        }
        .

    parse-error $program, X::Decorator::IllegalValue, "you can't just put any old value in an assoc decorator";
}

{
    my $program = q:to/./;
        @assoc("right")
        func infix:<@>(left, right) {
        }

        @equiv(infix:<@>)
        func infix:<@@>(left, right) {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("A" @@ "B" @@ "C");
        .

    outputs $program, "(A, (B, C))\n", "right associativity inherits through the equiv decorator";
}

{
    my $program = q:to/./;
        @assoc("non")
        func infix:<@>(left, right) {
        }

        @equiv(infix:<@>)
        func infix:<@@>(left, right) {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("A" @@ "B" @@ "C");
        .

    parse-error $program, X::Op::Nonassociative, "non-associativity inherits through the equiv decorator";
}

{
    my $program = q:to/./;
        @assoc("left")
        func infix:<%>(left, right) {
        }

        @equiv(infix:<%>)
        @assoc("right")
        func infix:<%%>(left, right) {
        }
        .

    parse-error $program, X::Associativity::Conflict,
        "if you're using the equiv decorator, you can't contradict the associativity";
}

{
    my $program = q:to/./;
        func prefix:<¿>(term) {
            return 42;
        }

        say(¿"forty-two");
        .

    outputs $program, "42\n", "declaring and using a prefix op works";
}

{
    my $program = q:to/./;
        func postfix:<!>(term) {
            return 1;
        }

        say([]!);
        .

    outputs $program, "1\n", "declaring and using a postfix op works";
}

{
    my $program = q:to/./;
        func prefix:<¿>(term) {
            return "prefix is looser";
        }

        func postfix:<!>(term) {
            return "postfix is looser";
        }

        func postfix:<$>(term) {
            return "postfix is looser";
        }

        func prefix:<%>(term) {
            return "prefix is looser";
        }

        say(¿[]!);
        say(%[]$);
        .

    outputs $program, "prefix is looser\n" x 2, "prefix is looser by default";
}

{
    my $program = q:to/./;
        func prefix:<¿>(term) {
            return "prefix is looser";
        }

        @looser(prefix:<¿>)
        func postfix:<!>(term) {
            return "postfix is looser";
        }

        func postfix:<$>(term) {
            return "postfix is looser";
        }

        @tighter(postfix:<$>)
        func prefix:<%>(term) {
            return "prefix is looser";
        }

        say(¿[]!);
        say(%[]$);
        .

    outputs $program, "postfix is looser\n" x 2, "postfixes can be made looser with decorators";
}

{
    my $program = q:to/./;
        func postfix:<!>(term) {
            return "postfix is looser";
        }

        @tighter(postfix:<!>)
        func prefix:<¿>(term) {
            return "prefix is looser";
        }

        func prefix:<%>(term) {
            return "prefix is looser";
        }

        @looser(prefix:<%>)
        func postfix:<$>(term) {
            return "postfix is looser";
        }

        say(¿[]!);
        say(%[]$);
        .

    outputs $program, "postfix is looser\n" x 2, "prefixes can be made tighter with decorators";
}

{
    my $program = q:to/./;
        @assoc("right")
        func postfix:<¡>(term) {
            return "postfix is looser";
        }

        @equiv(postfix:<¡>)
        func prefix:<¿>(term) {
            return "prefix is looser";
        }

        @assoc("left")
        func prefix:<%>(term) {
            return "prefix is looser";
        }

        @equiv(prefix:<%>)
        func postfix:<$>(term) {
            return "postfix is looser";
        }

        say(¿[]¡);
        say(%[]$);
        .

    outputs $program, "prefix is looser\npostfix is looser\n",
        "associativity works between pre- and postfixes";
}

{
    my $program = q:to/./;
        @assoc("non")
        func prefix:<¿>(left, right) {
        }

        @equiv(prefix:<¿>)
        func postfix:<!>(left, right) {
        }

        say(¿0!);
        .

    parse-error $program, X::Op::Nonassociative, "non-associativity inherits through the equiv decorator";
}

{
    my $program = q:to/./;
        @tighter(infix:<+>)
        func postfix:<!>(left, right) {
        }
        .

    parse-error $program, X::Precedence::Incompatible, "can't cross the infix/prepostfix prec barrier (I)";
}

{
    my $program = q:to/./;
        @tighter(prefix:<->)
        func infix:<!>(left, right) {
        }
        .

    parse-error $program, X::Precedence::Incompatible, "can't cross the infix/prepostfix prec barrier (II)";
}

{
    my $program = q:to/./;
        func infix:«!»(l, r) {
            return "Mr. Bond";
        }

        say(-13 ! none);
        .

    outputs $program, "Mr. Bond\n", "can declare an operator with infix:«...»";
}

{
    my $program = q:to/./;
        func infix:<\>>(l, r) {
            return "James";
        }

        say(0 > 7);
        .

    outputs $program, "James\n", "can declare an operator with a backslash in the name";
}

{
    my $program = q:to/./;
        @looser(prefix:<^>)
        func postfix:<‡>(x) {
            return [];
        }

        func prefix:<$>(x) {
            return x.size();
        }

        say($^5‡);
        .

    outputs $program, "[]\n", "Prepostfix boundaries are respected";
}

{
    my $program = q:to/./;
        func prefix:<&>(x) {
            return x ~ " prefix:<&>";
        }

        @looser(prefix:<&>)
        func postfix:<‡>(x) {
            return x ~ " postfix:<‡>";
        }

        {
            func prefix:<$>(x) {
                return x ~ " prefix:<$>";
            }

            say($&"application order:"‡);
        }
        .

    outputs $program, "application order: prefix:<&> prefix:<\$> postfix:<‡>\n", "Prepostfix boundaries are respected, #2";
}

{
    my $program = q:to/./;
        func postfix:<&>(x) {
            return 1;
        }

        func prefix:<&>(x) {
            return 2;
        }

        func prefix:<@>(x) {
            return 3;
        }

        # "I'm reminded of the day my daughter came in, looked over my
        # shoulder at some Perl 4 code, and said, 'What is that, swearing?'"
        #                                   -- Larry Wall, Usenet article
        say(@0&);
        .

    outputs $program, "3\n",
        "a postfix is looser than a prefix, even when it has a prefix of the same name (#190)";
}

{
    my $program = q:to/./;
        func infix:«->»(lhs, rhs) {
            return "Bond";
        }

        say(1 -> 2);
        .

    outputs $program, "Bond\n",
        "defining infix:«->» correctly installs a -> operator (#175)";
}

{
    my $program = q:to/./;
        my infix:<?> = func (lhs, rhs) {
            return "?";
        };

        say(1 ? 2);
        .

    outputs $program, "?\n",
        "installation of custom operators sits on the right peg (#173) (my)";
}

{
    my $program = q:to/./;
        func foo(x, y, infix:<+>) {
            return x + y;
        }

        say(foo(1, 2, func(l, r) { return l ~ r }));
        .

    outputs $program, "12\n",
        "installation of custom operators sits on the right peg (#173) (parameter I)";
}

{
    my $program = q:to/./;
        func foo(x, y, infix:<?>) {
            return x ? y;
        }

        say(foo(1, 2, func(l, r) { return l ~ r }));
        .

    outputs $program, "12\n",
        "installation of custom operators sits on the right peg (#173) (parameter II)";
}

{
    my $program = q:to/./;
        my fns = [func(l, r) { return l ~ r }, func(l, r) { return l * r }];

        for fns -> infix:<op> {
            say(20 op 5);
        }
        .

    outputs $program, "205\n100\n",
        "installation of custom operators sits on the right peg (#173) ('for' loop parameter)";
}

{
    my $program = q:to/./;
        if func(l, r) { return l * r } -> infix:<op> {
            say(20 op 5);
        }
        .

    outputs $program, "100\n",
        "installation of custom operators sits on the right peg (#173) ('if' statement parameter)";
}

{
    my $program = q:to/./;
        my c = 5;
        my d = fn;

        func fn(l, r) {
            c = c - 1;
            if !c {
                return none;
            }
            return fn;
        }

        while d -> infix:<op> {
            d = 1 op 2;
            say(c);
        }
        .

    outputs $program, "4\n3\n2\n1\n0\n",
        "installation of custom operators sits on the right peg (#173) ('while' statement parameter)";
}

{
    my $program = q:to/./;
        @looser(infix:<+>)
        func infix:<@->(a, b) {
            if b == 0 {
                return a;
            }
            return a-1 @- b-1;
        }

        say(10 @- 3);
        .

    outputs $program, "7\n",
        "can use custom operators already inside the body of the custom operator";
}

{
    my $program = q:to/./;
        func postfix:<++>(x) {
            x + 1
        }

        my y = 41;
        say(y ++)
        .

    outputs $program, "42\n",
        "can have whitespace before a postfix";
}

{
    my $program = q:to/./;
        say(+ 7);
        .

    outputs $program, "7\n",
        "can have whitespace after a prefix";
}

{
    my $program = q:to/./;
        func infix:<+++>(lhs, rhs) {}
        func postfix:<+++>(term) {}
        .

    parse-error $program, X::Redeclaration, "can't declare an infix and a postfix with the same name";
}

{
    my $program = q:to/./;
        {
            @assoc("right")
            func postfix:<!>(t) {
                "postfix:<!>(" ~ t ~ ")";
            }

            @equiv(postfix:<!>)
            func prefix:<?>(t) {
                "prefix:<?>(" ~ t ~ ")";
            }

            say(?"term"!);
        }
        {
            @assoc("right")
            func prefix:<?>(t) {
                "prefix:<?>(" ~ t ~ ")";
            }

            @equiv(prefix:<?>)
            func postfix:<!>(t) {
                "postfix:<!>(" ~ t ~ ")";
            }

            say(?"term"!);
        }
        .

    outputs
        $program,
        "prefix:<?>(postfix:<!>(term))\nprefix:<?>(postfix:<!>(term))\n",
        "with same-precedence right-associative prefix/postfix ops, the postfix evaluates first (no matter the order declared) (#372)";
}

{
    my $program = q:to/./;
        func prefix:<H>(n) {
            "oops"
        }
        say(H50);
    .

    parse-error $program, X::Undeclared, "prefixes that end in an alphanumeric must also end in a word boundary (#408) (I)";
}

{
    my $program = q:to/./;
        func prefix:<H5>(n) {
            "oops"
        }
        say(H50);
    .

    parse-error $program, X::Undeclared, "prefixes that end in an alphanumeric must also end in a word boundary (#408) (II)";
}

{
    my $program = q:to/./;
        func infix:<H>(x, y) {
            "oops"
        }
        say(2 H40);
    .

    parse-error $program, X::AdHoc, "infixes that end in an alphanumeric must also end in a word boundary (I)";
}

{
    my $program = q:to/./;
        func infix:<H4>(x, y) {
            "oops"
        }
        say(2 H40);
    .

    parse-error $program, X::AdHoc, "infixes that end in an alphanumeric must also end in a word boundary (II)";
}

{
    my $program = q:to/./;
        func postfix:<P>(n) { "oops" }
        say(2 PP)
    .

    parse-error $program, X::AdHoc, "postfixes that end in an alphanumeric must also end in a word boundary";
}

{
    my $program = q:to/./;
        func cornflake:<!!>() { "this should not even compile" }
        say(cornflake:<!!>);
    .

    parse-error $program, X::Category::Unknown, "can't use an unknown category when declaring a new op";
}

done-testing;
