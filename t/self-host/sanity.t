use Test;
use _007;
use _007::Value;

my class StrOutput {
    has $.result = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

sub run_007_on_007($program) {
    my $compunit = _007.parser.parse($program);
    my $runtime-program = slurp("self-host/runtime.007");
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    my $ast = _007.parser(:$runtime).parse($runtime-program);
    set-dict-property($ast.block.static-lexpad, "ast", $compunit);
    $runtime.run($ast);
    return $output.result;
}

is run_007_on_007(q[]), "", "empty program";
is run_007_on_007(q[say("Hello, James");]),
    "Hello, James\n",
    "simple print statement";

done-testing;
