use v6;
use Test;
use _007::Test;

my @exprs = «
    "1"                 "(int 1)"
    "1 + 2"             "(+ (int 1) (int 2))"
    "1 + 2 + 3"         "(+ (+ (int 1) (int 2)) (int 3))"
    "1 = 2"             "(assign (int 1) (int 2))"
    "1 = 2 + 3"         "(assign (int 1) (+ (int 2) (int 3)))"
    "-1"                "(- (int 1))"
    "--1"               "(- (- (int 1)))"
    "1 = 2 + 3 == 4"    "(assign (int 1) (== (+ (int 2) (int 3)) (int 4)))"
    "1[2]"              "(index (int 1) (int 2))"
»;

for @exprs -> $expr, $frag {
    my $ast = "(statements (stexpr {$frag}))";

    parses-to $expr, $ast, $expr;
}

done;
