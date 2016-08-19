use v6;
use Test;

sub find($dir, Regex $pattern) {
    my @targets = dir($dir);
    gather while @targets {
        my $file = @targets.shift;
        take $file if $file ~~ $pattern;
        if $file.IO ~~ :d {
            @targets.append: dir($file);
        }
    }
}

my $files = find(".", /[".pm" | ".t"] $/)\
    .grep({ $_ !~~ / "no-commented-out-debug-code.t" / })\
    .join(" ");

for '#say', '# say', '#dd', '# dd' -> $word {
    my @lines-with-stray-comment =
        qqx[grep -Fwrin '$word' $files].lines;

    is @lines-with-stray-comment.join("\n"), "",
        "no commented-out debug code ('$word')";
}

done-testing;
