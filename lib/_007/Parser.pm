use _007::Q;
use _007::Parser::OpScope;
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

    method types {
        return %(
            "Q::Identifier"          => Q::Identifier.attributes,
            "Q::Literal::None"       => Q::Literal::None.attributes,
            "Q::Literal::Int"        => Q::Literal::Int.attributes,
            "Q::Literal::Str"        => Q::Literal::Str.attributes,
            "Q::Term::Array"         => Q::Term::Array.attributes,
            "Q::Term::Object"        => Q::Term::Object.attributes,
            "Q::Property"            => Q::Property.attributes,
            "Q::PropertyList"        => Q::PropertyList.attributes,
            "Q::Block"               => Q::Block.attributes,
            "Q::Expr::Block"         => Q::Expr::Block.attributes,
            "Q::Identifier"          => Q::Identifier.attributes,
            "Q::Unquote"             => Q::Unquote.attributes,
            "Q::Prefix::Minus"       => Q::Prefix::Minus.attributes,
            "Q::Infix::Addition"     => Q::Infix::Addition.attributes,
            "Q::Infix::Concat"       => Q::Infix::Concat.attributes,
            "Q::Infix::Assignment"   => Q::Infix::Assignment.attributes,
            "Q::Infix::Eq"           => Q::Infix::Eq.attributes,
            "Q::Postfix::Index"      => Q::Postfix::Index.attributes,
            "Q::Postfix::Call"       => Q::Postfix::Call.attributes,
            "Q::Postfix::Property"   => Q::Postfix::Property.attributes,
            "Q::ParameterList"       => Q::ParameterList.attributes,
            "Q::ArgumentList"        => Q::ArgumentList.attributes,
            "Q::Statement::My"       => Q::Statement::My.attributes,
            "Q::Statement::Constant" => Q::Statement::Constant.attributes,
            "Q::Statement::Expr"     => Q::Statement::Expr.attributes,
            "Q::Statement::If"       => Q::Statement::If.attributes,
            "Q::Statement::Block"    => Q::Statement::Block.attributes,
            "Q::CompUnit"            => Q::CompUnit.attributes,
            "Q::Statement::For"      => Q::Statement::For.attributes,
            "Q::Statement::While"    => Q::Statement::While.attributes,
            "Q::Statement::Return"   => Q::Statement::Return.attributes,
            "Q::Statement::Sub"      => Q::Statement::Sub.attributes,
            "Q::Statement::Macro"    => Q::Statement::Macro.attributes,
            "Q::Statement::BEGIN"    => Q::Statement::BEGIN.attributes,
            "Q::StatementList"       => Q::StatementList.attributes,
            "Q::Trait"               => Q::Trait.attributes,
            "Q::Term::Quasi"         => Q::Term::Quasi.attributes,
        );
    }

    method parse($program) {
        my %*assigned;
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
