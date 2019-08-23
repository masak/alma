use Alma::Runtime;
use Alma::Parser;
use Alma::Linter;

class Alma {
    method runtime(:$input = $*IN, :$output = $*OUT, :@arguments) {
        Alma::Runtime.new(:$input, :$output, :@arguments);
    }

    method parser(:$runtime = $.runtime) {
        Alma::Parser.new(:$runtime);
    }

    method !parser-with-no-output {
        my $output = my role NoOutput { method flush() {}; method print($) {} };
        my $runtime = self.runtime(:$output);
        self.parser(:$runtime);
    }

    method linter(:$parser = self!parser-with-no-output) {
        Alma::Linter.new(:$parser);
    }
}
