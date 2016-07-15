use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (begin (block (parameterlist) (statementlist
            (stexpr (postfix:() (identifier "say") (argumentlist (str "won't get printed"))))))))
        .

    is-result $ast, "", "BEGIN blocks don't run at runtime";
}

{
    my $program = q:to/./;
        say("Why, the early bird gets the villain.");

        BEGIN {
            say("So early, Mr. Bond");
        }
        .

    outputs
        $program,
        "So early, Mr. Bond\nWhy, the early bird gets the villain.\n",
        "BEGIN blocks execute during parse";
}

{
    my $program = q:to/./;
        my r = 7;
        say(r);

        BEGIN {
            say(r);
        }
        .

    outputs
        $program,
        "None\n7\n",
        "variables are declared already at parse time (but not assigned)";
}

{
    my $program = q:to/./;
        {
            my k;
            BEGIN {
                k = 5;
            }
        }
        my k;
        BEGIN {
            say(k);
        }
        .

    outputs
        $program,
        "None\n",
        "BEGIN blocks are scoped just like everything else";
}

{
    my $program = q:to/./;
        my k;
        BEGIN {
            k = 23;
        }
        say(k);
        .

    outputs
        $program,
        "23\n",
        "values survive from BEGIN time to runtime";
}

{
    my $program = q:to/./;
        {
            my k;
            BEGIN {
                k = 117;
            }
            say(k);
        }
        .

    outputs
        $program,
        "117\n",
        "...same, but inside an immediate block";
}

{
    my $program = q:to/./;
        sub f() {
            my k;
            BEGIN {
                k = 2;
            }
            say(k);
        }

        f();
        .

    outputs
        $program,
        "2\n",
        "...same, but inside a sub";
}

{
    my $program = q:to/./;
        if 3 {
            my k;
            BEGIN {
                k = 419;
            }
            say(k);
        }
        .

    outputs
        $program,
        "419\n",
        "...same, but inside an if statement";
}

{
    my $program = q:to/./;
        for [1, 2] {
            my k;
            BEGIN {
                k = 1000;
            }
            say(k);
        }
        .

    outputs
        $program,
        "1000\n1000\n",
        "...same, but inside a for loop";
}

{
    my $program = q:to/./;
        my c = 3;
        while c = c + -1 {
            my k;
            BEGIN {
                k = 1000;
            }
            say(k);
        }
        .

    outputs
        $program,
        "1000\n1000\n",
        "...same, but inside a while loop";
}

{
    my $program = q:to/./;
        BEGIN {
            my k;
            BEGIN {
                k = 1000;
            }
            say(k);
        }
        .

    outputs
        $program,
        "1000\n",
        "...same, but inside a BEGIN block";
}

{
    my $program = q:to/./;
        sub foo() {
            say(7);
        }

        BEGIN { foo() }
        .

    outputs
        $program,
        "7\n",
        "calling a sub at BEGIN time works";
}

done-testing;
