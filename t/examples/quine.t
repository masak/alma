use Test;
use Alma::Test;

my @lines = run-and-collect-lines("examples/quine.alma");

is @lines.map({ "$_\n" }).join,
    slurp("examples/quine.alma"),
    "the quine outputs itself";

done-testing;
