use _007::Val;
use _007::Value;
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
            unless ?get-array-length($compunit.block.statementlist.statements);

        my @builtins;
        my @main;

        for get-all-array-elements($compunit.block.statementlist.statements) -> $stmt {
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
                && is-q-term-identifier($expr.operand)
                && $expr.operand.slots<name>.native-value eq "say" {

                @builtins.push(%builtins<say>);
                my @arguments = get-all-array-elements($expr.argumentlist.arguments).map: {
                    die "Cannot handle non-literal-Str arguments just yet!"
                        unless is-q-literal-str($_);
                    .slots<value>.quoted-Str;
                };
                @main.push("say({@arguments.join(", ")});");
            }

            when $expr ~~ Q::Term::My {
                my $name = $expr.identifier.slots<name>.native-value;
                @main.push("let {$name};");
            }

            when $expr ~~ Q::Infix::Assignment
                && $expr.lhs ~~ Q::Term::My {

                my $lhs = $expr.lhs;
                my $name = $lhs.identifier.slots<name>.native-value;
                my $rhs = $expr.rhs;

                die "Cannot handle non-literal-Int rhs just yet!"
                        unless is-q-literal-int($rhs);
                my $int = $rhs.slots<value>.native-value.Str;
                @main.push("let {$name} = {$int};");
            }

            die "Cannot handle this type of Q::Statement::Expr yet!";
        }
    }
}
