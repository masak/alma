use Test;
use _007;

my $program = q:to/EOF/;
    my iterations = ^101;
    iterations.shift();

    for iterations -> n {
        if n %% 15 {
            say("FizzBuzz");
        }
        else if n %% 3 {
            say("Fizz");
        }
        else if n %% 5 {
            say("Buzz");
        }
        else {
            say(n);
        }
    }
    EOF

my class LinesOutput {
    has $!result handles <lines> = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

my $output = LinesOutput.new;
given _007.runtime(:input($*IN), :$output) -> $runtime {
    my $ast = _007.parser(:$runtime).parse($program);
    $runtime.run($ast);
}

is +$output.lines, 100, "correct number of lines";

GROUP:
for ^7 -> $group {
    for ^15 -> $n {
        my $i = $group * 15 + $n + 1;
        my $actual = $output.lines[$i - 1];
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
