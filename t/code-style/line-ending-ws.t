use v6;
use Test;

my @lines-ending-with-ws =
    qx[find lib/ -name \*.pm | xargs -n1 perl6 -e'
        sub MAIN($file) {
            for $file.IO.lines.kv -> $i, $line {
                if $line ~~ /\h $/ {
                    say "$file {$i + 1}: $line.subst(/\h* $/, -> $/ { chr(0x2620) x $/.chars })";
                }
            }
        }'].lines;

is @lines-ending-with-ws.join("\n"), "", "no whitespace at the end of a line in .pm files";

done-testing;
