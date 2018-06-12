use v6;
use Test;
use _007;
use _007::Linter;

{
    my $program = 'func f() {}';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "func not used";
}

{
    my $program = 'func f() {}; f()';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "func is used; no complaint";
}

{
    my $program = 'func f() {}; say(f)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "func is used as argument; no complaint";
}

{
    my $program = '{ func f() {} }; func f() {}; f()';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "outer func used, but not inner";
}

{
    my $program = '{ func f() {}; f() }; func f() {}';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "inner func used, but not outer";
}

{
    my $program = 'func f() {}; for [1, 2, 3] { f() }';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "using a func from a more nested scope than it was defined";
}

done-testing;
