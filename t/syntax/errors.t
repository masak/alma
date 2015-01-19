use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        sub !() {}
        .

    parse-error $program, X::Syntax::Missing, "must have a valid identifier after `sub`";
}

done;
