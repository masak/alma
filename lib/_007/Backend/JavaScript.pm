use _007::Object;

my %builtins =
    "say" => q:to '----',
        function say(arg) {
            console.log(arg);
        }
        ----
;

class _007::Backend::JavaScript {
    method emit(_007::Object $compunit) {
        return ""
            unless $compunit.properties<block>.properties<statementlist>.properties<statements>.value;

        my @builtins;
        my @main;

        for $compunit.properties<block>.properties<statementlist>.properties<statements>.value -> $stmt {
            emit-stmt($stmt);
        }

        my $builtins = @builtins.map({ "$_\n" }).join;
        my $main = @main.join("\n");
        return qq:to 'PROGRAM';
            {$builtins}(() => \{ // main program
            {$main.indent(4)}
            \})();
            PROGRAM

        sub emit-stmt(_007::Object $stmt) {
            if $stmt.isa("Q::Statement::Expr") {
                my $expr = $stmt.properties<expr>;
                when $expr.isa("Q::Postfix::Call")
                    && $expr.properties<operand>.isa("Q::Identifier")
                    && $expr.properties<operand>.properties<name>.value eq "say" {

                    @builtins.push(%builtins<say>);
                    my @arguments = $expr.properties<argumentlist>.properties<arguments>.value.map: {
                        die "Cannot handle non-literal-Str arguments just yet!"
                            unless .isa("Q::Literal::Str");
                        # XXX: should really type-check the result of the .repr() call
                        bound-method(.properties<value>, "repr")().value;
                    };
                    @main.push("say({@arguments.join(", ")});");
                }

                die "Cannot handle this type of Q::Statement::Expr yet!";
            }
            elsif $stmt.isa("Q::Statement::My") {
                my $name = $stmt.properties<identifier>.properties<name>.value;
                if $stmt.properties<expr> !=== NONE {
                    die "Cannot handle non-literal-Int rhs just yet!"
                        unless $stmt.properties<expr>.isa("Q::Literal::Int");
                    my $expr = stringify($stmt.properties<expr>.properties<value>);
                    @main.push("let {$name} = {$expr};");
                }
                else {
                    @main.push("let {$name};");
                }
            }
            else {
                die "Cannot handle {$stmt.type.name}";
            }
        }
    }
}
