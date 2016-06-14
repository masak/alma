use Test;
use _007::Test;

my @lines = run-and-collect-output("examples/hello-world.007");

is +@lines, 1, "one line of output";
is @lines[0], "Hello, world!", "correct output";

done-testing;
