use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        if None { say("falsy none") }
        if 0 { say("falsy int") }
        if 7 { say("truthy int") }
        if "" { say("falsy str") }
        if "James" { say("truthy str") }
        if [] { say("falsy array") }
        if [""] { say("truthy array") }
        func foo() {}
        if foo { say("truthy sub") }
        macro moo() {}
        if moo { say("truthy macro") }
        if {} { say("falsy object") }
        if { a: 3 } { say("truthy object") }
        if Q.Literal.Int { say("truthy qnode") }
        .

    outputs $program,
        <int str array sub macro object qnode>.map({"truthy $_\n"}).join,
        "if statements run truthy things";
}

{
    my $program = q:to/./;
        if 7 -> a {
            say(a);
        }
        .

    outputs $program, "7\n",
        "if statements with parameters work as they should";
}

{
    my $program = q:to/./;
        if 1 {
            say("if");
        }
        else {
            say("else");
        }
        .

    outputs $program, "if\n",
        "if-else statement run if clause";
}

{
    my $program = q:to/./;
        if 0 {
            say("if");
        }
        else {
            say("else");
        }
        .

    outputs $program, "else\n",
        "if-else statement run else clause";
}

{
    my $program = q:to/./;
        if 0 {
            say("if");
        }
        else if 0 {
            say("else if");
        }
        else {
            say("else");
        }
        .

    outputs $program, "else\n",
        "if-else-if-else statement run else clause";
}

{
    my $program = q:to/./;
        if 0 {
            say("if");
        }
        else if 1 {
            say("else if");
        }
        else {
            say("else");
        }
        .

    outputs $program, "else if\n",
        "if-else-if-else statement run else-if clause";
}

{
    my $program = q:to/./;
        if 0 {
        }
        say("no parsefail");
        .

    outputs
        $program,
        "no parsefail\n",
        "regression test -- newline after an if block is enough, no semicolon needed";
}

{
    my $program = q:to/./;
        if 1 -> a, b {
            say("this should not work");
        }
        .

    runtime-error
        $program,
        X::ParameterMismatch,
        "if statement accepts only 0 or 1 argument";
}

{
    my $program = q:to/./;
        if 0 {
        }
        else -> v {
            say("the value is falsy and it is " ~ v);
        }
        .

    outputs
        $program,
        "the value is falsy and it is 0\n",
        "else blocks can have a parameter, too (#323)";
}

done-testing;
