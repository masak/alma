use v6;
use Test;

sub find($dir, Regex $pattern) {
    my @targets = dir($dir);
    my @files;
    while @targets {
        my $file = @targets.shift;
        push @files, $file if $file ~~ $pattern;
        if $file.IO ~~ :d {
            @targets.append: dir($file);
        }
    }
    return @files;
}

my @lines-with-unorthodox-indent;
for find("lib/", /".pm" $/) -> $file {
    for $file.IO.lines.kv -> $i, $line {
        next unless $line ~~ /^ \h+/;

        my $indent = ~$/;
        my $loc = "$file {$i + 1}";
        if $indent ~~ /\t/ {
            push @lines-with-unorthodox-indent,
                "$loc: TAB character in indent";
        }
        elsif $indent !~~ /^ " "* $/ {
            push @lines-with-unorthodox-indent,
                "$loc: non-space character in indent";
        }
        elsif (my $k = $indent.chars) !%% 4 {
            push @lines-with-unorthodox-indent,
                "$loc: {$k}-space indent";
        }
    }
}

is @lines-with-unorthodox-indent.join("\n"), "", "all lines have four-space indents";

done-testing;
