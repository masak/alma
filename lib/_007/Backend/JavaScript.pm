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

        for $compunit.block.statementlist.statements.elements -> $stmt {
            emit-stmt($stmt);
        }

        my $builtins = @builtins.map({ "$_\n" }).join;
        my $main = @main.join("\n");
        return qq:to 'PROGRAM';
            {$builtins}(() => \{ // main program
            {$main.indent(4)}
            \})();
            PROGRAM

        multi emit-stmt(Q::Statement $stmt) {
            die "Cannot handle {$stmt.^name}";
        }

        multi emit-stmt(Q::Statement::Expr $stmt) {
            my $expr = $stmt.expr;
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

        multi emit-stmt(Q::Statement::My $stmt) {
            my $name = $stmt.identifier.name.value;
            if $stmt.expr !~~ NONE {
                die "Cannot handle non-literal-Int rhs just yet!"
                        unless $stmt.expr ~~ Q::Literal::Int;
                my $expr = $stmt.expr.value.Str;
                @main.push("let {$name} = {$expr};");
            }
            else {
                @main.push("let {$name};");
            }
        }
    }
}
