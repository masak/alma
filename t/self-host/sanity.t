use Test;
use Alma;

my class StrOutput {
    has $.result = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

sub run_alma_on_alma($program) {
    my $compunit = Alma.parser.parse($program);
    my $runtime-program = slurp("self-host/runtime.alma");
    my $output = StrOutput.new;
    my $runtime = Alma.runtime(:$output);
    my $ast = Alma.parser(:$runtime).parse($runtime-program);
    $ast.block.static-lexpad.properties<ast> = $compunit;
    $runtime.run($ast);
    return $output.result;
}

is run_alma_on_alma(q[]), "", "empty program";
is run_alma_on_alma(q[say("Hello, James");]),
    "Hello, James\n",
    "simple print statement";

done-testing;
