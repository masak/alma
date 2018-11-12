use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        @constant
        my STATE = "alive";

        say(STATE);
        .

    outputs $program, "alive\n", "decorators can decorate 'my' statements";
}

{
    my $program = q:to/./;
        @equiv(infix:<+>)
        func infix:<&>(lhs, rhs) {
            return lhs ~ rhs;
        }

        say("James" & " " & "Bond");
        .

    outputs $program, "James Bond\n", "decorators can decorate 'func' statements";
}

{
    my $program = q:to/./;
        @equiv(infix:<+>, 42, "foo")
        func infix:<&>(lhs, rhs) {
        }
        .

    parse-error
        $program,
        X::ParameterMismatch,
        "can't decorate with the wrong number of parameters (equiv)";
}

{
    my $program = q:to/./;
        @assoc("left", 42, "foo")
        func infix:<&>(lhs, rhs) {
        }
        .

    parse-error
        $program,
        X::ParameterMismatch,
        "can't decorate with the wrong number of parameters (assoc)";
}

done-testing;
