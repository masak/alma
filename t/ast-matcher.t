use Test;
use _007::Val;
use _007::Q;
use _007::Test::Matcher;

sub matcher($description) {
    return Matcher.new($description);
}

given matcher(q:to ".") {
    CompUnit
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

given matcher(q:to ".") {
    CompUnit
        ...
    .

    my $empty-compunit = Q::CompUnit.new(
        :block(Q::Block.new(
            :parameterlist(Q::ParameterList.new()),
            :statementlist(Q::StatementList.new()),
        )),
    );
    ok !.matches($empty-compunit), "doesn't match an empty compunit";

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
    ok .matches($nonempty-compunit), "matches a nonempty compunit";
}

given matcher(q:to ".") {
    CompUnit
        Statement::Expr
            Literal::None
    .

    my $one-none = Q::CompUnit.new(
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
    ok .matches($one-none), "matches a compunit with a None";

    my $two-nones = Q::CompUnit.new(
        :block(Q::Block.new(
            :parameterlist(Q::ParameterList.new()),
            :statementlist(Q::StatementList.new(
                :statements(Val::Array.new(
                    :elements([
                        Q::Statement::Expr.new(
                            :expr(Q::Literal::None.new())
                        ),
                        Q::Statement::Expr.new(
                            :expr(Q::Literal::None.new())
                        ),
                    ]),
                )),
            )),
        )),
    );
    ok !.matches($two-nones), "doesn't match a compunit with two None statements";
}

given matcher(q:to ".") {
    CompUnit
        Statement::Expr
            Literal::None
        ...
    .

    my $one-none = Q::CompUnit.new(
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
    ok !.matches($one-none), "doesn't match a compunit with just one None";

    my $two-nones = Q::CompUnit.new(
        :block(Q::Block.new(
            :parameterlist(Q::ParameterList.new()),
            :statementlist(Q::StatementList.new(
                :statements(Val::Array.new(
                    :elements([
                        Q::Statement::Expr.new(
                            :expr(Q::Literal::None.new())
                        ),
                        Q::Statement::Expr.new(
                            :expr(Q::Literal::None.new())
                        ),
                    ]),
                )),
            )),
        )),
    );
    ok .matches($two-nones), "matches a compunit with two None statements";
}

given matcher(q:to ".") {
    Postfix [&call, @identifier = say]
        Literal::Str [@value = 42]
    .

    my $say-fortytwo = Q::Postfix::Call.new(
        :identifier(Q::Identifier.new(
            :name(Val::Str.new(:value("postfix:()"))),
        )),
        :operand(Q::Identifier.new(
            :name(Val::Str.new(:value("say"))),
        )),
        :argumentlist(Q::ArgumentList.new(
            :arguments(Val::Array.new(
                :elements([
                    Q::Literal::Int.new(
                        :value(Val::Int.new(:value(42))),
                    )
                ])
            )),
        )),
    );
    ok .matches($say-fortytwo), "matches say(42)";
}

given matcher(q:to ".") {
    say(...)
        Literal::Str [@value = 42]
    .

    my $say-fortytwo = Q::Postfix::Call.new(
        :identifier(Q::Identifier.new(
            :name(Val::Str.new(:value("postfix:()"))),
        )),
        :operand(Q::Identifier.new(
            :name(Val::Str.new(:value("say"))),
        )),
        :argumentlist(Q::ArgumentList.new(
            :arguments(Val::Array.new(
                :elements([
                    Q::Literal::Int.new(
                        :value(Val::Int.new(:value(42))),
                    )
                ])
            )),
        )),
    );
    ok .matches($say-fortytwo), "sugar `say(...)` for `Postfix [&call, @identifier = say]`";
}

done-testing;
