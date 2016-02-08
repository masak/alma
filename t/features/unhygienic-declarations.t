use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        macro moo() {
            return Q::Statement::My {
                identifier: Q::Identifier {
                    name: "agent_name"
                },
                expr: Q::Literal::Str {
                    value: "James Bond"
                }
            };
        }

        my agent_name = "Pink Panther!";
        {
            moo();
            say(agent_name);
        }
        say(agent_name);
        .

    outputs
        $program,
        "James Bond\nPink Panther!\n",
        "injecting a `my` with an unhygienic identifier causes a declaration";
}

{
    my $program = q:to/./;
        macro mar() {
            return quasi {
                my agent_name = "ninja, cus I'm invisible!";
            }
        }

        my agent_name = "Bond. James Bond.";
        {
            mar();
            say(agent_name);
        }
        .

    outputs
        $program,
        "Bond. James Bond.\n",
        "injecting a `my` from a quasi remains hygienic";
}

done-testing;
