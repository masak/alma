use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        sub infix:<*>(left, right) {
        }
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "infix:<*>") (parameters (ident "left") (ident "right")) (statements)))
        .

    parses-to $program, $ast, "custom operator parses to the right thing";
}

{
    my $program = q:to/./;
        sub infix:<*>(left, right) {
            return 20;
        }

        say(4 * 5);
        .

    outputs $program, "20\n", "using an operator after defining it works";
}

{
    my $program = q:to/./;
        say(4 * 5);
        .

    parse-error $program, X::AdHoc, "infix:<*> should not be defined unless we define it";
}

{
    my $program = q:to/./;
        {
            sub infix:<*>(left, right) {
                return 7;
            }
        }
        say(4 * 5);
        .

    parse-error $program, X::AdHoc, "infix:<*> should not be usable outside of its scope";
}

{
    my $program = q:to/./;
        sub infix:<+>(left, right) {
            return 14;
        }

        say(1 + 4);
        .

    outputs $program, "14\n", "can override a built-in operator";
}

{
    my $program = q:to/./;
        sub infix:<~~>(left, right) {
            return "wrong";
        }

        sub infix:<~~~>(left, right) {
            return "right";
        }

        say(4 ~~~ 5);
        .

    outputs $program, "right\n", "longest token wins, not first";
}

{
    my $program = q:to/./;
        sub infix:<***>(left, right) {
            return "right";
        }

        sub infix:<**>(left, right) {
            return "wrong";
        }

        say(4 *** 5);
        .

    outputs $program, "right\n", "longest token wins, not last";
}

{
    my $program = q:to/./;
        sub infix:<!>(left, right) {
            say(left ~ " " ~ right);
        }

        BEGIN { "OH" ! "HAI" }
        .

    outputs $program, "OH HAI\n", "defined operators work from within BEGIN blocks";
}

{
    my $program = q:to/./;
        sub infix:<*!>(left, right) {
            return 10;
        }

        say(1 + 5 *! 5);
        .

    outputs $program, "11\n", "new operators bind maximally tightly";
}

{
    my $program = q:to/./;
        sub infix:<~?>(left, right) is looser(infix:<+>) {
            return 6;
        }

        say(1 + 9 ~? 12);
        .

    outputs $program, "6\n", "can specify trait to bind loose";
}

{
    my $program = q:to/./;
        sub infix:<~?>(left, right) is tighter(infix:<+>) {
            return 6;
        }

        say(1 + 9 ~? 12);
        .

    outputs $program, "7\n", "can specify trait to bind tight";
}

{
    my $program = q:to/./;
        sub infix:<*>(left, right) {
            return 18;
        }

        sub infix:<~@>(left, right) is tighter(infix:<+>) {
            return 30;
        }

        say(1 ~@ 2 * 9);
        .

    outputs $program, "30\n", "the new op is tighter than +, but not *";
}

{
    my $program = q:to/./;
        sub infix:<!?!>(left, right) is tighter(infix:<+>) is looser(infix:<+>) {
        }
        .

    parse-error $program, X::Trait::Conflict, "can't have both tighter and looser traits";
}

done;
