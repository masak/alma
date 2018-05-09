use v6;
use Test;
use _007::Test;

my @exprs = «
    "1"                 "(int 1)"
    "1 + 2"             "(infix:+ (int 1) (int 2))"
    "1 + 2 + 3"         "(infix:+ (infix:+ (int 1) (int 2)) (int 3))"
    "-1"                "(prefix:- (int 1))"
    "--1"               "(prefix:- (prefix:- (int 1)))"
    "1[2]"              "(postfix:[] (int 1) (int 2))"
    "1 + (2 + 3)"       "(infix:+ (int 1) (infix:+ (int 2) (int 3)))"
»;

for @exprs -> $expr, $frag {
    my $ast = qq[(statementlist (my (identifier "a")) (stexpr {$frag}))];

    parses-to "my a; $expr", $ast, $expr;
}

done-testing;
