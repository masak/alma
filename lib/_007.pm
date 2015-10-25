use _007::Runtime;
use _007::Parser;

role _007 {
    method runtime(:$output = $*OUT) {
        _007::Runtime.new(:$output);
    }

    method parser(:$runtime = $.runtime) {
        _007::Parser.new(:$runtime);
    }
}
