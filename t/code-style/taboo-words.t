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

my @taboo-words = <
    ident
    paramlist
    params
    stmtlist
    arglist
    args
    proplist
    qx[find
    qx!find
>;

my $files = find(".", /[".pm" | ".t"] $/)\
        .grep({ $_ !~~ / "taboo-words.t" / })\
        .join(" ");

for @taboo-words -> $WORD {
    my @lines-with-taboo-words =
        qqx[grep -Fwrin $WORD $files].lines\
            # exception: `signature.params` happens in two places;
            # that's the Perl 6 Signature class
            .grep({ $_ !~~ / "signature.params" / });

    is @lines-with-taboo-words.join("\n"), "",
        "the word '$WORD' is not mentioned in the code base";
}

done-testing;
