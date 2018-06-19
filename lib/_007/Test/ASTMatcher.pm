use _007::Q;

class ASTMatcher {
    has $!matcher-fn;

    method new($description) {
        my $matcher-fn;
        for $description.lines -> $line {
            $line ~~ /^ (\w+) [\s+ "[empty]"]? $/;
            my $qtype-string = ~$0;
            my $qtype = ::("Q::{$qtype-string}");
            $matcher-fn = -> $qtree { $qtree ~~ $qtype };
        }
        return self.bless(:$matcher-fn);
    }

    submethod BUILD(:$!matcher-fn) {}

    method matches(Q $qtree) {
        return $!matcher-fn($qtree);
    }
}
