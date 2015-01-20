use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        sub infix:<*>(left, right) {
        }
        .

    my $ast = q:to/./;
        (statements
          (sub (ident "infix:<*>") (parameters (ident "left") (ident "right")) (statements)))
        .

    parses-to $program, $ast, "custom operator parses to the right thing";
}

done;
