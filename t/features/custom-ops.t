use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        func infix:<n>(left, right) {
        }
        .

    my $ast = q:to/./;
        (statementlist
          (stfunc (identifier "infix:n") (block (parameterlist (param (identifier "left")) (param (identifier "right"))) (statementlist))))
        .

    parses-to $program, $ast, "custom operator parses to the right thing";
}

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
        func infix:<*!>(left, right) {
            return 10;
        }

        say(1 + 5 *! 5);
        .

    outputs $program, "11\n", "new operators bind maximally tightly";
}

{
    my $program = q:to/./;
        func infix:<~?>(left, right) is looser(infix:<+>) {
            return 6;
        }

        say(1 + 9 ~? 12);
        .

    outputs $program, "6\n", "can specify trait to bind loose";
}

{
    my $program = q:to/./;
        func infix:<~?>(left, right) is tighter(infix:<+>) {
            return 6;
        }

        say(1 + 9 ~? 12);
        .

    outputs $program, "7\n", "can specify trait to bind tight";
}

{
    my $program = q:to/./;
        func infix:<*>(left, right) {
            return 18;
        }

        func infix:<~@>(left, right) is tighter(infix:<+>) {
            return 30;
        }

        say(1 ~@ 2 * 9);
        .

    outputs $program, "30\n", "the new op is tighter than +, but not *";
}

{
    my $program = q:to/./;
        func infix:<!?!>(left, right) is tighter(infix:<+>) is looser(infix:<+>) {
        }
        .

    parse-error $program, X::Trait::Conflict, "can't have both tighter and looser traits";
}

{
    my $program = q:to/./;
        func infix:<!?!>(left, right) is equal(infix:<+>) is equal(infix:<*>) {
        }
        .

    parse-error $program, X::Trait::Duplicate, "can't use the same trait more than once";
}


{
    my $program = q:to/./;
        func infix:<@>(left, right) {
            return "@";
        }

        func infix:<!>(left, right) is equal(infix:<@>) {
            return "!";
        }

        say(10 @ 2 ! 3);
        say(30 ! 2 @ 14);
        .

    outputs $program, "!\n@\n", "can specify trait to bind equal";
}

{
    my $program = q:to/./;
        func infix:<!?!>(left, right) is tighter(infix:<+>) is equal(infix:<+>) {
        }
        .

    parse-error $program, X::Trait::Conflict, "can't have both tighter and equal traits";
}

{
    my $program = q:to/./;
        func infix:<!++>(left, right) is looser(infix:<+>) is equal(infix:<+>) {
        }
        .

    parse-error $program, X::Trait::Conflict, "can't have both looser and equal traits";
}

{
    my $program = q:to/./;
        func infix:<@>(left, right) is assoc("right") {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("A" @ "B" @ "C");
        .

    outputs $program, "(A, (B, C))\n", "associativity means we can control the shape of the expr tree";
}

{
    my $program = q:to/./;
        func infix:<%>(left, right) is assoc("left") {
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
        func infix:<!>(left, right) is assoc("non") {
            return "oh, James";
        }

        say(0 ! 7);
        .

    outputs $program, "oh, James\n", "can define an operator to be non-associative";
}

{
    my $program = q:to/./;
        func infix:<!>(left, right) is assoc("non") {
            return "oh, James";
        }

        say(0 ! 0 ! 7);
        .

    parse-error $program, X::Op::Nonassociative, "a non-associative operator can't associate";
}

{
    my $program = q:to/./;
        func infix:<&-&>(left, right) is assoc("salamander") {
        }
        .

    parse-error $program, X::Trait::IllegalValue, "you can't just put any old value in an assoc trait";
}

{
    my $program = q:to/./;
        func infix:<@>(left, right) is assoc("right") {
        }

        func infix:<@@>(left, right) is equal(infix:<@>) {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("A" @@ "B" @@ "C");
        .

    outputs $program, "(A, (B, C))\n", "right associativity inherits through the 'is equal' trait";
}

{
    my $program = q:to/./;
        func infix:<@>(left, right) is assoc("non") {
        }

        func infix:<@@>(left, right) is equal(infix:<@>) {
            return "(" ~ left ~ ", " ~ right ~ ")";
        }

        say("A" @@ "B" @@ "C");
        .

    parse-error $program, X::Op::Nonassociative, "non-associativity inherits through the 'is equal' trait";
}

{
    my $program = q:to/./;
        func infix:<%>(left, right) is assoc("left") {
        }

        func infix:<%%>(left, right) is equal(infix:<%>) is assoc("right") {
        }
        .

    parse-error $program, X::Associativity::Conflict,
        "if you're using the 'is equal' trait, you can't contradict the associativity";
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

        func postfix:<!>(term) is looser(prefix:<¿>) {
            return "postfix is looser";
        }

        func postfix:<$>(term) {
            return "postfix is looser";
        }

        func prefix:<%>(term) is tighter(postfix:<$>) {
            return "prefix is looser";
        }

        say(¿[]!);
        say(%[]$);
        .

    outputs $program, "postfix is looser\n" x 2, "postfixes can be made looser with traits";
}

{
    my $program = q:to/./;
        func postfix:<!>(term) {
            return "postfix is looser";
        }

        func prefix:<¿>(term) is tighter(postfix:<!>) {
            return "prefix is looser";
        }

        func prefix:<%>(term) {
            return "prefix is looser";
        }

        func postfix:<$>(term) is looser(prefix:<%>) {
            return "postfix is looser";
        }

        say(¿[]!);
        say(%[]$);
        .

    outputs $program, "postfix is looser\n" x 2, "prefixes can be made tighter with traits";
}

{
    my $program = q:to/./;
        func postfix:<¡>(term) is assoc("right") {
            return "postfix is looser";
        }

        func prefix:<¿>(term) is equal(postfix:<¡>) {
            return "prefix is looser";
        }

        func prefix:<%>(term) is assoc("left") {
            return "prefix is looser";
        }

        func postfix:<$>(term) is equal(prefix:<%>) {
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
        func prefix:<¿>(left, right) is assoc("non") {
        }

        func postfix:<!>(left, right) is equal(prefix:<¿>) {
        }

        say(¿0!);
        .

    parse-error $program, X::Op::Nonassociative, "non-associativity inherits through the 'is equal' trait";
}

{
    my $program = q:to/./;
        func postfix:<!>(left, right) is tighter(infix:<+>) {
        }
        .

    parse-error $program, X::Precedence::Incompatible, "can't cross the infix/prepostfix prec barrier (I)";
}

{
    my $program = q:to/./;
        func infix:<!>(left, right) is tighter(prefix:<->) {
        }
        .

    parse-error $program, X::Precedence::Incompatible, "can't cross the infix/prepostfix prec barrier (II)";
}

{
    my $program = q:to/./;
        func infix:«!»(l, r) {
            return "Mr. Bond";
        }

        say(-13 ! None);
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
        func postfix:<‡>(x) is looser(prefix:<^>) {
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

        func postfix:<‡>(x) is looser(prefix:<&>) {
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
        constant infix:<?> = func (lhs, rhs) {
            return "?";
        };

        say(1 ? 2);
        .

    outputs $program, "?\n",
        "installation of custom operators sits on the right peg (#173) (constant)";
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
                return None;
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

done-testing;
