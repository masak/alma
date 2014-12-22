use _007::Runtime;
use _007::Parser;

role _007 {
    method runtime(:$output = $*OUT) {
        Runtime.new(:$output);
    }

    method parser {
        Parser.new;
    }
}
