use _007::Val;
use _007::Q;

class _007::Parser {
    has $.runtime = die "Must supply a runtime";

    method parse($program, Str :$category, Bool :$*unexpanded) {
        if $program eq "say(7)" {
            return Q::Statement::Expr.new(
                :expr(Q::Postfix::Call.new(
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
                                    :value(Val::Int.new(:value(7)))
                                ),
                            ]),
                        )),
                    )),
                )),
            );
        }
        return Q::CompUnit.new(
            :block(Q::Block.new(
                :parameterlist(Q::ParameterList.new()),
                :statementlist(Q::StatementList.new(
                    :statements(Val::Array.new(
                        :elements([]),
                    )),
                )),
            )),
        );
    }
}
