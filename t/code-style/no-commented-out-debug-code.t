use v6;
use Test;
use _007::Test;

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
