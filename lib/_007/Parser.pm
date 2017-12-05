use _007::Parser::Syntax;
use _007::Parser::Actions;

class _007::Parser {
    has $.runtime = die "Must supply a runtime";
    has @!opscopes = $!runtime.builtin-opscope;
    has @!checks;

    method opscope { @!opscopes[*-1] }
    method push-opscope { @!opscopes.push: @!opscopes[*-1].clone }
    method pop-opscope { @!opscopes.pop }

    method postpone(&check:()) { @!checks.push: &check }

    method parse($program, Bool :$*unexpanded) {
        my %*assigned;
        my @*declstack;
        my $*insub = False;
        my $*parser = self;
        my $*runtime = $!runtime;
        @!checks = ();
        _007::Parser::Syntax.parse($program, :actions(_007::Parser::Actions))
            or die "Could not parse program";   # XXX: make this into X::
        for @!checks -> &check {
            &check();
        }
        return $/.ast;
    }
}
