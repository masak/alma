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
    method emit(_007::Value $compunit where &is-q-compunit) {
        return ""
            unless ?get-array-length($compunit.slots<block>.slots<statementlist>.slots<statements>);

        my @builtins;
        my @main;

        for get-all-array-elements($compunit.slots<block>.slots<statementlist>.slots<statements>) -> $stmt {
            emit-stmt($stmt);
        }

        my $builtins = @builtins.map({ "$_\n" }).join;
        my $main = @main.join("\n");
        return qq:to 'PROGRAM';
            {$builtins}(() => \{ // main program
            {$main.indent(4)}
            \})();
            PROGRAM

        multi emit-stmt(_007::Value $stmt where &is-q-statement) {
            die "Cannot handle {$stmt.^name}";
        }

        multi emit-stmt(_007::Value $stmt where &is-q-statement-expr) {
            my $expr = $stmt.slots<expr>;
            when is-q-postfix-call($expr)
                && is-q-identifier($expr.slots<operand>)
                && $expr.slots<operand>.slots<name>.native-value eq "say" {

                @builtins.push(%builtins<say>);
                my @arguments = get-all-array-elements($expr.slots<argumentlist>.slots<arguments>).map: {
                    die "Cannot handle non-literal-Str arguments just yet!"
                        unless is-q-literal-str($_);
                    .value.quoted-Str;
                };
                @main.push("say({@arguments.join(", ")});");
            }

            when is-q-term-my($expr) {
                my $name = $expr.slots<identifier>.slots<name>.native-value;
                @main.push("let {$name};");
            }

            when is-q-infix-assignment($expr)
                && is-q-term-my($expr.slots<lhs>) {

                my $lhs = $expr.slots<lhs>;
                my $name = $lhs.slots<identifier>.slots<name>.native-value;
                my $rhs = $expr.slots<rhs>;

                die "Cannot handle non-literal-Int rhs just yet!"
                        unless is-q-literal-int($rhs);
                my $int = $rhs.slots<value>.native-value.Str;
                @main.push("let {$name} = {$int};");
            }

            die "Cannot handle this type of Q.Statement.Expr yet!";
        }
    }
}
