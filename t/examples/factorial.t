use Test;
use _007::Test;

my @lines = run-and-collect-lines("examples/factorial.007");

is +@lines, 4, "correct number of lines of output";
is @lines[0], "1", "line #1 correct";
is @lines[1], "1", "line #2 correct";
is @lines[2], "120", "line #3 correct";
is @lines[3], "2432902008176640000", "line #4 correct";

done-testing;
