use Test;
use _007::Test;

my class CannedInput {
    has @.lines;
    method with(@lines) { self.bless(:@lines) }
    method get() { @.lines.shift // Nil }
};

{
    my $input = CannedInput.with(lines q:to 'EOF');
        133
        105
        EOF

    my @lines = run-and-collect-output("examples/euclid-gcd.007", :$input);

    is @lines[*-1], "Greatest common denominator: 7", "gcd of 133 and 105 is 7";
}

{
    my $input = CannedInput.with(lines q:to 'EOF');
        47
        43
        EOF

    my @lines = run-and-collect-output("examples/euclid-gcd.007", :$input);

    is @lines[*-1], "Greatest common denominator: 1", "two primes are coprime";
}

{
    my $input = CannedInput.with(lines q:to 'EOF');
        -35
        15
        EOF

    my @lines = run-and-collect-output("examples/euclid-gcd.007", :$input);

    is @lines[*-1], "Greatest common denominator: 5", "minus signs are ignored";
}

done-testing;
