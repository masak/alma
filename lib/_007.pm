use _007::Runtime;
use _007::Parser;
use _007::Linter;

class _007 {
    method runtime(:$output = $*OUT) {
        _007::Runtime.new(:$output);
    }

    method parser(:$runtime = $.runtime) {
        _007::Parser.new(:$runtime);
    }

    method !parser-with-no-output {
        my $output = my role NoOutput { method say($) {} };
        my $runtime = self.runtime(:$output);
        self.parser(:$runtime);
    }

    method linter(:$parser = self!parser-with-no-output) {
        _007::Linter.new(:$parser);
    }
}
