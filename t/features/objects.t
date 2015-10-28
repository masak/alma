use v6;
use Test;
use _007::Test;

my @exprs = «
    '{}'  "(object)"
    '{"a": 1}' '(object (property (str "a") (int 1)))'
    '{a}' '(object (property (str "a") (ident "a")))'
    '{a : 1}' '(object (property (str "a") (int 1)))'
    '{a: 1}' '(object (property (str "a") (int 1)))'
    '{a() {}}' '(object (property (str "a") (block (paramlist) (stmtlist))))'
    '{a(a, b) {}}' '(object (property (str "a") (block 
      (paramlist (ident "a") (ident "b")) (stmtlist))))'
»;

for @exprs -> $expr, $frag {
    my $ast = qq[(stmtlist (my (ident "a")) (stexpr {$frag}))];

    parses-to "my a; ($expr)", $ast, $expr;
}

done-testing;
