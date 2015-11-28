use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my q = Q::Literal::Int { value: 7 };

        say(melt(q));
        .

    outputs
        $program,
        qq[7\n],
        "melt() on literal int";
}

{
    my $ast = q:to/./;
        (stmtlist
          (my (ident "q")
            (object (ident "Q::Statement::My") (proplist
              (property "ident" (object (ident "Q::Identifier") (proplist
                (property "name" (str "agent")))))
              (property "expr" (str "James Bond")))))
          (stexpr (postfix:<()> (ident "melt") (arglist (ident "q")))))
        .

    is-error
        $ast,
        X::TypeCheck,
        "cannot melt() a statement";
}

{
    my $program = q:to/./;
        my x = "Bond";
        my q = Q::Identifier { name: "x" };

        say(melt(q));
        .

    outputs
        $program,
        qq[Bond\n],
        "melt() on a variable";
}

done-testing;
