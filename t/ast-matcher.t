use Test;
use _007::Val;
use _007::Q;
use _007::Test::Matcher;

sub matcher($description) {
    return Matcher.new($description);
}

given matcher(q:to ".") {
    CompUnit [&empty]
    .

    my $empty-compunit = Q::CompUnit.new(
        :block(Q::Block.new(
            :parameterlist(Q::ParameterList.new()),
            :statementlist(Q::StatementList.new()),
        )),
    );
    ok .matches($empty-compunit), "matches an empty compunit";

    my $nonempty-compunit = Q::CompUnit.new(
        :block(Q::Block.new(
            :parameterlist(Q::ParameterList.new()),
            :statementlist(Q::StatementList.new(
                :statements(Val::Array.new(
                    :elements([
                        Q::Statement::Expr.new(
                            :expr(Q::Literal::None.new())
                        ),
                    ]),
                )),
            )),
        )),
    );
    ok !.matches($nonempty-compunit), "doesn't match a nonempty compunit";
}

done-testing;
