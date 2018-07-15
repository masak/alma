use Test;
use _007::Test;

my @lines = run-and-collect-lines("examples/in.007");

is +@lines, 12, "correct number of lines of output";
for [1, 2], [3, 4], [5, 6], [7, 8], [9, 10], [11, 12] -> [$L1, $L2] {
    is @lines[$L1 - 1], "True", "line #{$L1} correct";
    is @lines[$L2 - 1], "False", "line #{$L2} correct";
}

done-testing;
