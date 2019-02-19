use Test;
use _007::Test;

my @lines = run-and-collect-lines("examples/swap.007");

is +@lines, 1, "correct number of lines of output";
is @lines[0], "OH HAI", "line #1 correct";

done-testing;
