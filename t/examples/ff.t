use Test;
use _007::Test;

my @lines = run-and-collect-output("examples/ff.007").lines;

{
    is @lines[^5].join, "xBxBx", "ff works";
}

{
    is @lines[5 .. @lines.elems-1].join, "xBABx", "fff works";
}

done-testing;
