use v6;
use Test;
use _007::Test;

my $output = qx[perl6 bin/count-builtins];

for $output.lines {
    if /^ (<-[:]>+) ":" \h* (\d+) $ / {
        ok +$1 > 0, "have $1 {$0.lc}";
    }
}

done-testing;
