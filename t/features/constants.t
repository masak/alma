use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        say("runtime");
        constant C = 4;
        BEGIN {
            say(C);
        }
        .

    outputs
        $program,
        "4\nruntime\n",
        "constants are assigned and visible at BEGIN time";
}

{
    my $program = q:to/./;
        constant C = -9;
        say(C);
        .

    outputs
        $program,
        "-9\n",
        "constants are visible from runtime";
}

{
    my $program = q:to/./;
        constant C = 1;
        constant D = C + 1;
        say(D);
        .

    outputs
        $program,
        "2\n",
        "constants are visible from other constants";
}

{
    my $program = q:to/./;
        constant C;
        .

    parse-error
        $program,
        X::Syntax::Missing,
        "constant declarations must have an assignment (#83)";
}

{
    my $program = q:to/./;
        constant C = 42;
        C = 5;
        .

    parse-error
        $program,
        X::Assignment::RO,
        "cannot assign to a constant (#68)";
}

{
    my $program = q:to/./;
        constant C = 42;
        if 1 {
            C = 8;
        }
        .

    parse-error
        $program,
        X::Assignment::RO,
        "cannot assign to a constant (assignment is in a nested block) (#68)";
}

{
    my $program = q:to/./;
        constant C = "so very constant";
        {
            my C = "override";
            C = "ok to assign";
            say(C);
        }
        say(C);
        .

    outputs
        $program,
        "ok to assign\nso very constant\n",
        "the 'cannot assign to constant' error is aware of lexical overrides (#68)";
}

done-testing;
