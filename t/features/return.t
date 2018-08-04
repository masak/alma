use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        func f() {
            return 7;
        }

        say(f());
        .

    outputs $program, "7\n", "sub returning an Int";
}

{
    my $program = q:to/./;
        func f() {
            return "Bond. James Bond.";
        }

        say(f());
        .

    outputs $program, "Bond. James Bond.\n", "sub returning a Str";
}

{
    my $program = q:to/./;
        func f() {
            return [1, 2, "three"];
        }

        say(f());
        .

    outputs $program, qq<[1, 2, "three"]\n>, "sub returning a Str";
}

{
    my $program = q:to/./;
        func f() {
            return 1953;
            say("Dead code. Should have returned by now");
        }

        say(f());
        .

    outputs $program, "1953\n", "a return statement forces immediate exit of the subroutine";
}

{
    my $program = q:to/./;
        func f() {
            return;
        }

        say(f());
        .

    outputs $program, "None\n", "sub returning nothing";
}

{
    my $program = q:to/./;
        func f() {
            7;
        }

        say(f());
        .

    outputs $program, "7\n", "sub returning implicitly";
}

done-testing;
