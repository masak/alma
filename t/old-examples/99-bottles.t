use Test;
use Alma;

my $program = q:to/EOF/;
    func verse(n) {
        func plural(n, thing) {
            if n == 1 {
                return n ~ " " ~ thing;
            }
            else {
                return n ~ " " ~ thing ~ "s";
            }
        }

        say(plural(n + 1, "bottle"), " of beer on the wall,");
        say(plural(n + 1, "bottle"), " of beer.");
        say("Take one down, pass it around,");
        say(plural(n, "bottle"), " of beer on the wall...");
    }

    for (^99).reverse() -> beerCount {
        verse(beerCount);
        if beerCount > 0 {
            say();
        }
    }
    EOF

my class LinesOutput {
    has $!result handles <lines> = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

my $output = LinesOutput.new;
given Alma.runtime(:input($*IN), :$output) -> $runtime {
    my $ast = Alma.parser(:$runtime).parse($program);
    $runtime.run($ast);
}

is +$output.lines, 4 * 99 + 98, "correct number of lines";

is $output.lines[^4].join("\n"), q:to/VERSE/.trim, "first verse";
    99 bottles of beer on the wall,
    99 bottles of beer.
    Take one down, pass it around,
    98 bottles of beer on the wall...
    VERSE

is $output.lines[36 * 5 .. 36 * 5 + 3].join("\n"), q:to/VERSE/.trim, "37th verse";
    63 bottles of beer on the wall,
    63 bottles of beer.
    Take one down, pass it around,
    62 bottles of beer on the wall...
    VERSE

is $output.lines[*-4 .. *-1].join("\n"), q:to/VERSE/.trim, "last verse";
    1 bottle of beer on the wall,
    1 bottle of beer.
    Take one down, pass it around,
    0 bottles of beer on the wall...
    VERSE

done-testing;
