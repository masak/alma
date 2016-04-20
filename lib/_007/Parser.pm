use _007::Parser::Syntax;
use _007::Parser::Actions;

class _007::Parser {
    has $.runtime = die "Must supply a runtime";
    has @!oplevels = $!runtime.builtin-opscope;
    has @!checks;

    method oplevel { @!oplevels[*-1] }
    method push-oplevel { @!oplevels.push: @!oplevels[*-1].clone }
    method pop-oplevel { @!oplevels.pop }

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
