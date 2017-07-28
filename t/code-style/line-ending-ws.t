use v6;
use Test;
use _007::Test;

my @lines-ending-with-ws;
for find(".", /".pm" $/) -> $file {
    for $file.IO.lines.kv -> $i, $line {
        if $line ~~ /\h $/ {
            push @lines-ending-with-ws,
                "$file {$i + 1}: " ~
                $line.subst(/\h* $/, -> $/ { chr(0x2620) x $/.chars });
        }
    }
}

is @lines-ending-with-ws.join("\n"), "", "no whitespace at the end of a line in .pm files";

done-testing;
