use Test;

my $output = qx[perl6 bin/007 examples/99-bottles.007];
my @lines = lines($output);

is +@lines, 4 * 99 + 98, "correct number of lines";

is @lines[^4].join("\n"), q:to/VERSE/.trim, "first verse";
    99 bottles of beer on the wall,
    99 bottles of beer.
    Take one down, pass it around,
    98 bottles of beer on the wall...
    VERSE

is @lines[36 * 5 .. 36 * 5 + 3].join("\n"), q:to/VERSE/.trim, "37th verse";
    63 bottles of beer on the wall,
    63 bottles of beer.
    Take one down, pass it around,
    62 bottles of beer on the wall...
    VERSE

is @lines[*-4 .. *-1].join("\n"), q:to/VERSE/.trim, "last verse";
    1 bottle of beer on the wall,
    1 bottle of beer.
    Take one down, pass it around,
    0 bottles of beer on the wall...
    VERSE

done-testing;
