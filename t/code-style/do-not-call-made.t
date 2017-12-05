use v6;
use Test;

my @lines-with-made =
    qqx[grep -Fwrin '.made' lib/_007/Parser/Actions.pm].lines;

is @lines-with-made.join("\n"), "",
    "all .ast method calls are spelled '.ast' and not '.made'";

done-testing;
