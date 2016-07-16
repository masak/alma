use Test;
use _007::Test;

my @lines = run-and-collect-output("examples/fizzbuzz.007");

is +@lines, 100, "correct number of lines";

GROUP:
for ^7 -> $group {
    for ^15 -> $n {
        my $i = $group * 15 + $n + 1;
        my $actual = @lines[$i - 1];
        my $expected = [
            $i, $i, "Fizz", $i, "Buzz",
            "Fizz", $i, $i, "Fizz", "Buzz",
            $i, "Fizz", $i, $i, "FizzBuzz"
        ][$n];
        is $actual, $expected, "Line $i has the expected output";

        last GROUP if $i == 100;
    }
}

done-testing;
