use v6;
use Test;
use Alma;
use Alma::Test;

{
    my $program = q:to/./;
        func MAIN() {
            say("Bond");
        }
        .

    outputs $program, "Bond\n", "MAIN function runs automatically";
}

{
    my $program = q:to/./;
        my MAIN = "not a function";
        .

    outputs $program, "", "if MAIN exists but is not a function, nothing happens";
}

{
    my $program = q:to/./;
        func MAIN(first, last) {
            say(last, ", ", first, " ", last, ".");
        }
        .

    my $output = my class StrOutput {
        has $.result = "";

        method flush() {}
        method print($s) { $!result ~= $s.gist }
    }.new;

    my $runtime = Alma.runtime(:$output, :arguments("James", "Bond"));
    my $parser = Alma.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    is $output.result, "Bond, James Bond.\n", "can pass command-line arguments to MAIN";
}

{
    my $program = q:to/./;
        func MAIN(x) {
        }
        .

    my $output = my class StrOutput {
        has $.result = "";

        method flush() {}
        method print($s) { $!result ~= $s.gist }
    }.new;

    my $runtime = Alma.runtime(:$output, :arguments(["one", "two"]));
    my $parser = Alma.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    is $output.result, "Usage:\n  bin/007 <script> <x>\n", "usage message printed on too few arguments";
    is $runtime.exit-code, 1, "non-zero exit code (1) on too few arguments";
}

{
    my $program = q:to/./;
        func MAIN(x, y, z) {
        }
        .

    my $output = my class StrOutput {
        has $.result = "";

        method flush() {}
        method print($s) { $!result ~= $s.gist }
    }.new;

    my $runtime = Alma.runtime(:$output, :arguments(["один"]));
    my $parser = Alma.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    is $output.result, "Usage:\n  bin/007 <script> <x> <y> <z>\n", "usage message printed on too many arguments";
    is $runtime.exit-code, 1, "non-zero exit code (1) on too many arguments";
}

done-testing;
