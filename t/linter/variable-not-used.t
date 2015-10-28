use v6;
use Test;
use _007;
use _007::Linter;

{
    my $program = 'my x';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::VariableNotUsed], "variable not used";
}

{
    my $program = 'my x = 7; say(x)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "variable is used; no complaint";
}

{
    my $program = 'my x = 7; say(x + x)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "variable is used in an expression; no complaint";
}

{
    my $program = '{ my x }; my x = 7; say(x)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::VariableNotUsed], "outer variable used, but not inner";
}

{
    my $program = '{ my x = 7; say(x) }; my x = 5';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::VariableNotUsed], "inner variable used, but not outer";
}

{
    my $program = 'my x = 7; for [1, 2, 3] { say(x) }';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "using a variable from a more nested scope than it was defined";
}

done-testing;
