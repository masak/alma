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
            return new Q::Postfix::Call {
                identifier: new Q::Identifier { name: "postfix:<()>" },
                operand: new Q::Identifier { name: "say" },
                argumentlist: new Q::ArgumentList {
                    arguments: [new Q::Literal::Str { value: "OH HAI" }]
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
