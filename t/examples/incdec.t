use Test;
use _007::Test;

constant @forms = <prefix postfix>;
constant @ops = <++ -->;

constant NUMBER_OF_CASES = @forms * @ops;
constant LINES_PER_CASE = 4;
constant EXPECTED_NUMBER_OF_LINES = NUMBER_OF_CASES * LINES_PER_CASE;

my @lines = run-and-collect-lines("examples/incdec.007");

is +@lines, EXPECTED_NUMBER_OF_LINES, "correct number of lines";

my $base = 0;
for @forms -> $form {
    for @ops -> $op {
        my $before = 7;     # by definition
        my $after = $op eq "++"
            ?? $before + 1
            !! $before - 1;
        my $during = $form eq "postfix"
            ?? $before
            !! $after;

        ok @lines[$base + 0] eq "== {$form}:<{$op}>", "line {$base + 1} is correct";
        ok @lines[$base + 1] eq "before: {$before}", "line {$base + 2} is correct";
        ok @lines[$base + 2] eq "during: {$during}", "line {$base + 3} is correct";
        ok @lines[$base + 3] eq "after: {$after}", "line {$base + 4} is correct";

        $base += LINES_PER_CASE;
    }
}

done-testing;
