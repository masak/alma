use Test;
use _007;
use _007::Test::ASTMatcher;

{
    my $parser = _007.parser();
    my $actual = $parser.parse("");

    my $expected = ASTMatcher.new(q:to "---");
        CompUnit [empty]
        ---

    ok $expected.matches($actual), "empty program gives empty AST";
}

done-testing;
