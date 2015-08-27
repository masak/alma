use v6;
use Test;
use _007::Test;

my @exprs = «
    "1"                 "(int 1)"
    "1 + 2"             "(+ (int 1) (int 2))"
    "1 + 2 + 3"         "(+ (+ (int 1) (int 2)) (int 3))"
    "a = 2"             '(assign (ident "a") (int 2))'
    "a = 2 + 3"         '(assign (ident "a") (+ (int 2) (int 3)))'
    "-1"                "(- (int 1))"
    "--1"               "(- (- (int 1)))"
    "a = 2 + 3 == 4"    '(assign (ident "a") (== (+ (int 2) (int 3)) (int 4)))'
    "1[2]"              "(index (int 1) (int 2))"
    "1 + (2 + 3)"       "(+ (int 1) (+ (int 2) (int 3)))"
»;

for @exprs -> $expr, $frag {
    my $ast = qq[(statements (my (ident "a")) (stexpr {$frag}))];

    parses-to "my a; $expr", $ast, $expr;
}

done;
