use v6;
use Test;
use Alma;
use _007::Linter;

{
    my $program = 'func f() {}';
    my @complaints = Alma.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "func not used";
}

{
    my $program = 'func f() {}; f()';
    my @complaints = Alma.linter.lint($program);
    ok @complaints ~~ [], "func is used; no complaint";
}

{
    my $program = 'func f() {}; say(f)';
    my @complaints = Alma.linter.lint($program);
    ok @complaints ~~ [], "func is used as argument; no complaint";
}

{
    my $program = '{ func f() {} }; func f() {}; f()';
    my @complaints = Alma.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "outer func used, but not inner";
}

{
    my $program = '{ func f() {}; f() }; func f() {}';
    my @complaints = Alma.linter.lint($program);
    ok @complaints ~~ [L::SubNotUsed], "inner func used, but not outer";
}

{
    my $program = 'func f() {}; for [1, 2, 3] { f() }';
    my @complaints = Alma.linter.lint($program);
    ok @complaints ~~ [], "using a func from a more nested scope than it was defined";
}

done-testing;
