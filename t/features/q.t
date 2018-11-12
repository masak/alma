use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my q = new Q.Statement.Return {};
        say(q.expr);
        .

    outputs
        $program,
        "none\n",
        "Q.Statement.Return can be constructed without an 'expr' property (#84)";
}

{
    my $program = q:to/./;
        my q = new Q.Statement.If {
            expr: new Q.Literal.None {},
            block: new Q.Block {
                parameterlist: new Q.ParameterList {
                    parameters: []
                },
                statementlist: new Q.StatementList {
                    statements: []
                }
            }
        };
        say(q.else);
        .

    outputs
        $program,
        "none\n",
        "Q.Statement.If can be constructed without an 'else' property (#84)";
}

done-testing;
