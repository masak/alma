use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        my f;
        {
            f = 3;
            sub f() {
            }
        }
        .

    parse-error $program, X::Redeclaration::Outer, "cannot first use outer and then declare inner sub";
}

done-testing;
