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

{
    my $program = q:to/./;
        sub infix:<*>(left, right) {
            return 20;
        }

        say(4 * 5);
        .

    outputs $program, "20\n", "using an operator after defining it works";
}

{
    my $program = q:to/./;
        say(4 * 5);
        .

    parse-error $program, X::AdHoc, "infix:<*> should not be defined unless we define it";
}

done;
