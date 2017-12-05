use _007::Runtime;
use _007::Parser;
use _007::Linter;

class _007 {
    method runtime(:$input = $*IN, :$output = $*OUT) {
        _007::Runtime.new(:$input, :$output);
    }

    method parser(:$runtime = $.runtime) {
        _007::Parser.new(:$runtime);
    }

    method !parser-with-no-output {
        my $output = my role NoOutput { method flush() {}; method print($) {} };
        my $runtime = self.runtime(:$output);
        self.parser(:$runtime);
    }

    method linter(:$parser = self!parser-with-no-output) {
        _007::Linter.new(:$parser);
    }
}
