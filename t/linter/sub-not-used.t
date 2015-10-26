use v6;
use Test;
use _007;
use _007::Linter;

{
    my $program = 'sub f() {}';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "sub not used";
}

{
    my $program = 'sub f() {}; f()';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "sub is used; no complaint";
}

{
    my $program = 'sub f() {}; say(f)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "sub is used as argument; no complaint";
}

{
    my $program = '{ sub f() {} }; sub f() {}; f()';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "outer sub used, but not inner";
}

{
    my $program = '{ sub f() {}; f() }; sub f() {}';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "inner sub used, but not outer";
}

{
    my $program = 'sub f() {}; for [1, 2, 3] { f() }';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "using a sub from a more nested scope than it was defined";
}

done-testing;
