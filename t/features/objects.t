use v6;
use Test;
use _007::Test;

my @exprs = «
    '{}'  "(object)"
    '{"a": 1}' '(object (property (str "a") (int 1)))'
    '{a}' '(object (property (str "a") (ident "a")))'
    '{a : 1}' '(object (property (str "a") (int 1)))'
    '{a: 1}' '(object (property (str "a") (int 1)))'
    '{a() {}}' '(object (property (str "a") (block (parameters) (statements))))'
    '{a(a, b) {}}' '(object (property (str "a") (block 
      (parameters (ident "a") (ident "b")) (statements))))'
»;

for @exprs -> $expr, $frag {
    my $ast = qq[(statements (my (ident "a")) (stexpr {$frag}))];

    parses-to "my a; ($expr)", $ast, $expr;
}

done-testing;
