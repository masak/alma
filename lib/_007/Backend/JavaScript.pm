use _007::Q;

my %builtins =
    "say" => q:to '----',
        function say(arg) {
            console.log(arg);
        }
        ----
;

class _007::Backend::JavaScript {
    method emit(Q::CompUnit $compunit) {
        return ""
            unless $compunit.block.statementlist.statements.elements;

        my @builtins;
        my @main;

        for $compunit.block.statementlist.statements.elements -> $statement {
            when $statement ~~ Q::Statement::Expr {
                my $expr = $statement.expr;
                when $expr ~~ Q::Postfix::Call
                    && $expr.operand ~~ Q::Identifier
                    && $expr.operand.name.value eq "say" {

                    @builtins.push(%builtins<say>);
                    my @arguments = $expr.argumentlist.arguments.elements.map: {
                        die "Cannot handle non-literal-Str arguments just yet!"
                            unless $_ ~~ Q::Literal::Str;
                        .value.quoted-Str;
                    };
                    @main.push("say({@arguments.join(", ")});");
                }

                die "Cannot handle this type of Q::Statement::Expr yet!";
            }

            die "Cannot handle {$statement.^name} yet";
        }

        my $builtins = @builtins.map({ "$_\n" }).join;
        my $main = @main.join("\n");
        return qq:to 'PROGRAM';
            {$builtins}(() => \{ // main program
                {$main}
            \})();
            PROGRAM
    }
}
