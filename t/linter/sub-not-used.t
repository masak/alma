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

done-testing;
