use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my q = Q::Statement::My { identifier: Q::Identifier { name: "foo" } };
        say(q.expr);
        .

    outputs
        $program,
        "None\n",
        "Q::Statement::My can be constructed without an 'expr' property";
}

{
    my $program = q:to/./;
        my q = Q::Statement::Return {};
        say(q.expr);
        .

    outputs
        $program,
        "None\n",
        "Q::Statement::Return can be constructed without an 'expr' property";
}

{
    my $program = q:to/./;
        my q = Q::Statement::If {
            expr: Q::Literal::None {},
            block: Q::Block {
                parameterlist: Q::ParameterList {
                    parameters: []
                },
                statementlist: Q::StatementList {
                    statements: []
                }
            }
        };
        say(q.else);
        .

    outputs
        $program,
        "None\n",
        "Q::Statement::If can be constructed without an 'else' property";
}

{
    my $program = q:to/./;
        my q = Q::Statement::Sub {
            identifier: Q::Identifier { name: "foo" },
            block: Q::Block {
                parameterlist: Q::ParameterList { parameters: [] },
                statementlist: Q::StatementList { statements: [] }
            }
        };
        say(q.traitlist);
        .

    outputs
        $program,
        "Q::TraitList []\n",
        "Q::Statement::Sub can be constructed without a 'traitlist' property";
}

{
    my $program = q:to/./;
        my q = Q::Statement::Macro {
            identifier: Q::Identifier { name: "moo" },
            block: Q::Block {
                parameterlist: Q::ParameterList { parameters: [] },
                statementlist: Q::StatementList { statements: [] }
            }
        };
        say(q.traitlist);
        .

    outputs
        $program,
        "Q::TraitList []\n",
        "Q::Statement::Macro can be constructed without a 'traitlist' property";
}

done-testing;
