use Test;
use _007::Test;

my class CannedInput {
    has @.lines;
    method with(@lines) { self.bless(:@lines) }
    method get() { @.lines.shift // Nil }
};

{
    my $input = CannedInput.with(lines q:to 'EOF');
        2
        1
        6
        EOF

    my @lines = run-and-collect-output("examples/nicomachus.007", :$input);

    is @lines[*-1], "Your number was 41.", "correct output when the secret number was 41";
}

{
    my $input = CannedInput.with(lines q:to 'EOF');
        2
        1
        0
        EOF

    my @lines = run-and-collect-output("examples/nicomachus.007", :$input);

    is @lines[*-1], "Your number was 56.", "correct output when the secret number was 56";
}

{
    my $input = CannedInput.with(lines q:to 'EOF');
        1
        3
        5
        EOF

    my @lines = run-and-collect-output("examples/nicomachus.007", :$input);

    is @lines[*-1], "Your number was 103.", "correct output when the secret number was 103";
}

done-testing;
