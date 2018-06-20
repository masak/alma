use Test;
use _007;
use _007::Test::Matcher;

sub parse($program, :$category = "compunit") {
    return _007.parser.parse($program, :$category);
}

given parse('') -> $actual {
    my $expected = Matcher.new(q:to "---");
        CompUnit
        ---

    ok $expected.matches($actual), "empty program gives empty AST";
}

given parse('say(7)', :category("statement")) -> $actual {
    my $expected = Matcher.new(q:to "---");
        Statement::Expr
            Postfix [&call, @operand = say]
                7
        ---

    ok $expected.matches($actual), "parse a simple say(7) statement";
}

done-testing;
