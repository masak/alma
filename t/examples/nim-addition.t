use Test;
use _007::Test;

my @lines = run-and-collect-lines("examples/nim-addition.007");

is +@lines, 5, "correct number of lines of output";
is @lines[0], "0", "line #1 correct";
is @lines[1], "3", "line #2 correct";
is @lines[2], "0", "line #3 correct";
is @lines[3], "1", "line #4 correct";
is @lines[4], "8", "line #5 correct";

done-testing;
