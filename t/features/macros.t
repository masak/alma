use v6;
use Test;
use _007::Test;

{
    my $ast = q:to/./;
        (statements
          (macro (ident "f") (parameters) (statements
            (stexpr (call (ident "say") (arguments (str "OH HAI from inside macro")))))))
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
            return Q::Postfix::Call(
                Q::Identifier("say"),
                Q::Arguments([Q::Literal::Str("OH HAI")])
            );
        }

        foo();
        .

    outputs
        $program,
        "OH HAI\n",
        "expanding a macro and running the result at runtime";
}

done-testing;
