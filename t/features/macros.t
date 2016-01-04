use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statementlist
          (macro (identifier "f") (block (parameterlist) (statementlist
            (stexpr (postfix:<()> (identifier "say") (argumentlist (str "OH HAI from inside macro"))))))))
        .

    is-result $ast, "", "macro";
}

{
    my $program = q:to/./;
        macro foo() {
        }
        .

    outputs
        $program,
         "",
        "defining macro works";
}

{
    my $program = q:to/./;
        macro foo() {
            return Q::Postfix::Call {
                identifier: Q::Identifier { name: "postfix:<()>" },
                operand: Q::Identifier { name: "say" },
                argumentlist: Q::ArgumentList {
                    arguments: [Q::Literal::Str { value: "OH HAI" }]
                }
            };
        }

        foo();
        .

    outputs
        $program,
        "OH HAI\n",
        "expanding a macro and running the result at runtime";
}

{
    my $program = q:to/./;
        macro m() {}
        m = 18000;
        .

    parse-error
        $program,
        X::Assignment::RO,
        "cannot assign to a macro";
}

done-testing;
