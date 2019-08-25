use v6;
use Test;
use Alma::Test;

my @examples = find("examples", / ".alma" $/).map(-> $file { $file.basename.subst(/ ".alma" $/, "", :g) });

my @example-tests = find("t/examples", / ".t" $/).map(-> $file { $file.basename.subst(/ ".t" $/, "", :g) });

{
    my $missing-example-tests = (@examples (-) @example-tests).keys.map({ "- $_" }).join("\n");
    is $missing-example-tests, "", "all examples have a corresponding test file";
}

{
    my $superfluous-example-tests = (@example-tests (-) @examples).keys.map({ "- $_" }).join("\n");
    is $superfluous-example-tests, "", "all example test files have a corresponding example";
}

done-testing;
