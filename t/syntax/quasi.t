use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
         say(quasi { 1 + 1 });
    .
    outputs $program, read("(statements (stexpr (+ (int 1) (int 1))))")~"\n", "Basic quasi quoting";
}
