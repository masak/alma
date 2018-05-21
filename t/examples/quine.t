use Test;
use _007::Test;

my @lines = run-and-collect-lines("examples/quine.007");

is @lines.map({ "$_\n" }).join,
    slurp("examples/quine.007"),
    "the quine outputs itself";

done-testing;
