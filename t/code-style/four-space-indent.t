use v6;
use Test;

my @lines-with-unorthodox-indent =
    qx[find lib/ -name \*.pm | xargs -n1 perl6 -e'
        sub MAIN($file) {
            for $file.IO.lines.kv -> $i, $line {
                next unless $line ~~ /^ \h+/;

                my $indent = ~$/;
                my $loc = "$file {$i + 1}";
                if $indent ~~ /\t/ {
                    say "$loc: TAB character in indent";
                }
                elsif $indent !~~ /^ " "* $/ {
                    say "$loc: non-space character in indent";
                }
                elsif (my $k = $indent.chars) !%% 4 {
                    say "$loc: {$k}-space indent";
                }
            }
        }'].lines;

is @lines-with-unorthodox-indent.join("\n"), "", "all lines have four-space indents";

done-testing;
