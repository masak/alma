use v6;
use Test;
use _007::Test;

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

done;
