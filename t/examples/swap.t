use Test;
use Alma::Test;

my @lines = run-and-collect-lines("examples/swap.alma");

is +@lines, 1, "correct number of lines of output";
is @lines[0], "OH HAI", "line #1 correct";

done-testing;
