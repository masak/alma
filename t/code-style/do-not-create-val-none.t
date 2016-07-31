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
    .grep({ $_ !~~ / "do-not-create-val-none.t" / })\
    .join(" ");

my @lines-with-val-none-new =
    qqx[grep -Fwrin 'Val::None.new' $files].lines\
        # exception: we store Val::None.new once as a constant
        .grep({ $_ !~~ /  ":constant NONE is export = " / });

is @lines-with-val-none-new.join("\n"), "",
    "no unnecessary calls to Val::None.new";

done-testing;
