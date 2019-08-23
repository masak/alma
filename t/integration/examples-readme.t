use v6;
use Test;
use Alma::Test;

my @examples = find("examples", / ".alma" $/).map(*.basename);

my @example-readme-lines = lines("examples/README.md".IO);
my @example-headings = @example-readme-lines.grep(/^ "## "/);
my @example-readme-names = @example-headings.map({ / "[" (<-[\]]>*) "]" / && ~$0 });
my @example-readme-urls = @example-headings.map({ / "(" (<-[)]>*) ")" / && ~$0 });

{
    my $missing-example-headings = (@examples (-) @example-readme-names).keys.map({ "- $_" }).join("\n");
    is $missing-example-headings, "", "all examples have a corresponding heading in examples/README.md";
}

{
    my $superfluous-example-headings = (@example-readme-names (-) @examples).keys.map({ "- $_" }).join("\n");
    is $superfluous-example-headings, "", "all example headings in examples/README.md have a corresponding example";
}

for @example-readme-names Z @example-readme-urls -> ($name, $url) {
    is $url, "/examples/$name", "correct URL for $name";
}

done-testing;
