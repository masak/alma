use _007::Val;
use _007::Value;
use _007::Q;

role Lint {
    method message { ... }
}

class L::SubNotUsed does Lint {
    has $.name;
    method message { "Sub '$.name' is declared but never used." }
}

class L::VariableNotUsed does Lint {
    has $.name;
    method message { "Variable '$.name' is declared but never used." }
}

class L::VariableNeverAssigned does Lint {
    has $.name;
    method message { "Variable '$.name' is never assigned a value." }
}

class L::VariableReadBeforeAssigned does Lint {
    has $.name;
    method message { "Variable '$.name' was read before it was assigned." }
}

class L::RedundantAssignment does Lint {
    has $.name;
    method message { "Redundant assignment of variable '$.name' to itself is redundant." }
}

class X::AssertionFailure is Exception {
    has $.message;
    method new($message) { self.bless(:$message) }
}

class _007::Linter {
    has $.parser;

    method lint($program) {
        my %declared;
        my %used;
        my %assigned;
        my %readbeforeassigned;
        my @complaints;

        {
            my $root = $.parser.parse($program);
            traverse($root);

            my @blocks;

            multi traverse(_007::Value $stblock where &is-q-statement-block) {
                traverse($stblock.block);
            }

            multi traverse(_007::Value $block where &is-q-block) {
                @blocks.push: $block;
                traverse($block.statementlist);
                @blocks.pop;
            }

            multi traverse(_007::Value $parameterlist where &is-q-parameterlist) {
            }

            multi traverse(_007::Value $statementlist where &is-q-statementlist) {
                for get-all-array-elements($statementlist.statements) -> $stmt {
                    traverse($stmt);
                }
            }

            multi traverse(_007::Value $func where &is-q-statement-func) {
                my $name = $func.identifier.name;
                %declared{"{@blocks[*-1].WHICH.Str}|$name"} = L::SubNotUsed;
            }

            multi traverse(_007::Value $stexpr where &q-statement-expr) {
                traverse($stexpr.expr);
            }

            multi traverse(_007::Value $call where &q-postfix-call) {
                traverse($call.operand);
                traverse($call.argumentlist);
            }

            sub ref(Str $name) {
                for @blocks.reverse -> $block {
                    my $pad = $block.static-lexpad;
                    if get-dict-property($pad, $name) {
                        return "{$block.WHICH.Str}|$name";
                    }
                }
                fail X::AssertionFailure.new("A thing that is used must be declared somewhere");
            }

            multi traverse(_007::Value $identifier where &q-identifier) {
                my $name = $identifier.name.native-value;
                # XXX: what we should really do is whitelist all of he built-ins
                return if $name eq "say";
                my $ref = ref $name;

                %used{ref $name} = True;
                if !%assigned{ref $name} {
                    %readbeforeassigned{$ref} = True;
                }
            }

            multi traverse(_007::Value $argumentlist where &is-q-argumentlist) {
                for get-all-array-elements($argumentlist.arguments) -> $expr {
                    traverse($expr);
                }
            }

            multi traverse(_007::Value $literal where &is-q-literal) {
            }

            multi traverse(_007::Value $term where &is-q-term) {
            }

            multi traverse(_007::Value $my where &is-q-term-my) {
                my $name = $my.identifier.name;
                my $ref = "{@blocks[*-1].WHICH.Str}|$name";
                %declared{$ref} = L::VariableNotUsed;
            }

            multi traverse(_007::Value $for where &is-q-statement-for) {
                traverse($for.expr);
                traverse($for.block);
            }

            multi traverse(_007::Value $infix where &is-q-infix-assignment) {
                traverse($infix.rhs);
                my $lhs = $infix.lhs;
                if $lhs ~~ Q::Term::My {
                    $lhs = $lhs.identifier;
                }
                die "LHS was not an identifier"
                    unless $lhs ~~ Q::Identifier;
                my $name = $lhs.name.native-value;
                if $infix.rhs ~~ Q::Identifier && $infix.rhs.name eq $name {
                    @complaints.push: L::RedundantAssignment.new(:$name);
                }
                %assigned{ref $name} = True;
                traverse($infix.lhs);
            }

            multi traverse(_007::Value $infix where &is-q-infix) {
                traverse($infix.lhs);
                traverse($infix.rhs);
            }
        }

        for %declared.keys -> $ref {
            next if %used{$ref};
            my $name = $ref.subst(/^ .* \|/, "");
            my $linttype = %declared{$ref};
            @complaints.push: $linttype.new(:$name);
        }
        for %declared.keys -> $ref {
            next if %assigned{$ref};
            next if %declared{$ref} ~~ L::SubNotUsed;
            next if !%used{$ref};
            my $name = $ref.subst(/^ .* \|/, "");
            @complaints.push: L::VariableNeverAssigned.new(:$name);
            %readbeforeassigned{$ref} :delete;
        }
        for %declared.keys -> $ref {
            next unless %readbeforeassigned{$ref};
            next if %declared{$ref} ~~ L::SubNotUsed;
            my $name = $ref.subst(/^ .* \|/, "");
            @complaints.push: L::VariableReadBeforeAssigned.new(:$name);
        }

        return @complaints;
    }
}
