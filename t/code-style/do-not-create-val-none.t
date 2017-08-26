use v6;
use Test;
use _007::Test;

my $files = find(".", /[".pm" | ".t"] $/)\
    .grep({ $_ !~~ / "do-not-create-val-none.t" / })\
    .join(" ");

my @lines-with-val-none-new =
    qqx[grep -Fwrin '_007::Object.new(:type(TYPE<NoneType>)' $files].lines\
        # exception: we store _007::Object.new(:type(TYPE<NoneType>) once as a constant
        .grep({ $_ !~~ /  ":constant NONE is export = " / });

is @lines-with-val-none-new.join("\n"), "",
    "no unnecessary calls to _007::Object.new(:type(TYPE<NoneType>)";

done-testing;
