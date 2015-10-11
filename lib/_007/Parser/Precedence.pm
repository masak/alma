use _007::Q;

class _007::Parser::Precedence {
    has $.assoc = "left";
    has %.ops;

    method contains($op) {
        %.ops{$op}:exists;
    }

    method clone {
        self.new(:$.assoc, :%.ops);
    }
}
