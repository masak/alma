use v6;
use Test;
use _007;
use _007::Linter;

{
    my $program = 'my x; say(x)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::VariableNeverAssigned], "variable never assigned";
}

{
    my $program = 'my x; say(x); x = 42';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::VariableReadBeforeAssigned], "reading first and assigning later";
}

{
    my $program = 'my x; x = 42; say(x)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "assigning first and reading later is OK (I)";
}

{
    my $program = 'my x = 42; say(x)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "assigning first and reading later is OK (II)";
}

{
    my $program = 'my x; { x = 42 }; say(x)';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "assigning first and reading later is OK (III)";
}

{
    my $program = 'my x = x';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::RedundantAssignment], "assigning to self in declaration is redundant";
}

{
    my $program = 'my x = 7; x = x';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::RedundantAssignment], "assigning to self after declaration is also redundant";
}

{
    my $program = 'my x; for [1, 2, 3] { say(x); x = 42 }';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [L::VariableReadBeforeAssigned], "reading first and assigning later in loop";
}

{
    my $program = 'my x; for [1, 2, 3] { x = 42; say(x) }';
    my @complaints = _007.linter.lint($program);
    ok @complaints ~~ [], "assigning then reading in loop is OK";
}

done-testing;
