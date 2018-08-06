use Test;
use _007;

my $parser = _007.parser;

{
    my $program = 'quasi { if {{{0}}} {} }';
    my $stringified-ast = $parser.parse($program).Str;

    my $expected = q:to/./.subst(/\n$/, "");
        Q.CompUnit Q.Block {
            parameterlist: Q.ParameterList [],
            statementlist: Q.StatementList [Q.Statement.Expr Q.Term.Quasi {
                qtype: "",
                contents: Q.Block {
                    parameterlist: Q.ParameterList [],
                    statementlist: Q.StatementList [Q.Statement.If {
                        expr: Q.Unquote {
                            qtype: Q.Term,
                            expr: Q.Literal.Int 0
                        },
                        block: Q.Block {
                            parameterlist: Q.ParameterList [],
                            statementlist: Q.StatementList []
                        },
                        else: None
                    }]
                }
            }]
        }
        .

    is $stringified-ast, $expected, 'can turn a program with an unquote into a stringified AST';
}

done-testing;
