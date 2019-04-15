use Test;
use _007::Test;

my @lines = run-and-collect-lines("examples/send-more-money/stage-1.007");

is +@lines, 1, "correct number of lines of output";
is @lines[0], "9567 + 1085 == 10652", "line #1 correct (only solution)";

done-testing;
