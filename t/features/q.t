use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my q = new Q::Statement::My { identifier: new Q::Identifier { name: "foo" } };
        say(q.expr);
        .

    outputs
        $program,
        "None\n",
        "Q::Statement::My can be constructed without an 'expr' property (#84)";
}

{
    my $program = q:to/./;
        my q = new Q::Statement::Return {};
        say(q.expr);
        .

    outputs
        $program,
        "None\n",
        "Q::Statement::Return can be constructed without an 'expr' property (#84)";
}

{
    my $program = q:to/./;
        my q = new Q::Statement::If {
            expr: new Q::Literal::None {},
            block: new Q::Block {
                parameterlist: new Q::ParameterList {
                    parameters: []
                },
                statementlist: new Q::StatementList {
                    statements: []
                }
            }
        };
        say(q.else);
        .

    outputs
        $program,
        "None\n",
        "Q::Statement::If can be constructed without an 'else' property (#84)";
}

{
    my $program = q:to/./;
        my q = new Q::Statement::Sub {
            identifier: new Q::Identifier { name: "foo" },
            block: new Q::Block {
                parameterlist: new Q::ParameterList { parameters: [] },
                statementlist: new Q::StatementList { statements: [] }
            }
        };
        say(q.traitlist);
        .

    outputs
        $program,
        "Q::TraitList []\n",
        "Q::Statement::Sub can be constructed without a 'traitlist' property (#84)";
}

{
    my $program = q:to/./;
        my q = new Q::Statement::Macro {
            identifier: new Q::Identifier { name: "moo" },
            block: new Q::Block {
                parameterlist: new Q::ParameterList { parameters: [] },
                statementlist: new Q::StatementList { statements: [] }
            }
        };
        say(q.traitlist);
        .

    outputs
        $program,
        "Q::TraitList []\n",
        "Q::Statement::Macro can be constructed without a 'traitlist' property (#84)";
}

done-testing;
