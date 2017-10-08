use v6;
use Test;
use _007::Test;

my @failing-typechecks;

my @files = find(".", /".pm" $/);
for @files -> $file {
    given slurp($file.IO) -> $content {
        for $content.comb(/"X::Type.new" <-[;]>+ ";"/) -> $typecheck {
            next unless $typecheck ~~ /":expected(" (<-[)]>+) ")"/;
            next unless $0 ~~ /^ '"'/;
            @failing-typechecks.push("\n(In $file):\n$typecheck");
        }
    }
}

is @failing-typechecks.join("\n"), "", "No X::Type :expected uses a literal string";

done-testing;
