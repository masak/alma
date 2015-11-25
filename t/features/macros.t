use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (stmtlist
          (macro (ident "f") (block (paramlist) (stmtlist
            (stexpr (postfix:<()> (ident "say") (arglist (str "OH HAI from inside macro"))))))))
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
                expr: Q::Identifier { name: "say" },
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

done-testing;
