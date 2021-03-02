use v6;
use Test;
use Alma::Test;

my $files = find(".", /[".rakumod" | ".t"] $/)\
    .grep({ $_ !~~ / "no-commented-out-debug-code.t" / })\
    .join(" ");

for '#say', '# say', '#dd', '# dd' -> $word {
    my @lines-with-stray-comment =
        qqx[grep -Fwrin '$word' $files].lines;

    is @lines-with-stray-comment.join("\n"), "",
        "no commented-out debug code ('$word')";
}

done-testing;
