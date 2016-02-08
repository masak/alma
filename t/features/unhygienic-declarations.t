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

done-testing;
