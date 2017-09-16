use _007::Val;
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
            my @blocks;

            sub ref(Str $name) {
                for @blocks.reverse -> $block {
                    my $pad = $block.properties<static-lexpad>;
                    if $pad.value{$name} {
                        return "{$block.id}|$name";
                    }
                }
                fail X::AssertionFailure.new("A thing that is used must be declared somewhere");
            }

            sub traverse(_007::Object $node) {
                if $node.isa("Q::Statement::Block") -> $stblock {
                    traverse($stblock.properties<block>);
                }
                elsif $node.isa("Q::Block") -> $block {
                    @blocks.push: $block;
                    traverse($block.properties<parameterlist>);
                    traverse($block.properties<statementlist>);
                    @blocks.pop;
                }
                elsif $node.isa("Q::StatementList") -> $statementlist {
                    for $statementlist.properties<statements>.value -> $stmt {
                        traverse($stmt);
                    }
                }
                elsif $node.isa("Q::Statement::Sub") -> $sub {
                    my $name = $sub.properties<identifier>.properties<name>;
                    %declared{"{@blocks[*-1].id}|$name"} = L::SubNotUsed;
                }
                elsif $node.isa("Q::Statement::Expr") -> $stexpr {
                    traverse($stexpr.properties<expr>);
                }
                elsif $node.isa("Q::Postfix::Call") -> $call {
                    traverse($call.properties<operand>);
                    traverse($call.properties<argumentlist>);
                }
                elsif $node.isa("Q::Identifier") -> $identifier {
                    my $name = $identifier.properties<name>.value;
                    # XXX: what we should really do is whitelist all of he built-ins
                    return if $name eq "say";
                    my $ref = ref $name;

                    %used{ref $name} = True;
                    if !%assigned{ref $name} {
                        %readbeforeassigned{$ref} = True;
                    }
                }
                elsif $node.isa("Q::ArgumentList") -> $argumentlist {
                    for $argumentlist.properties<arguments>.value -> $expr {
                        traverse($expr);
                    }
                }
                elsif $node.isa("Q::Statement::For") -> $for {
                    traverse($for.properties<expr>);
                    traverse($for.properties<block>);
                }
                elsif $node.isa("Q::Statement::My") -> $my {
                    my $name = $my.properties<identifier>.properties<name>;
                    my $ref = "{@blocks[*-1].id}|$name";
                    %declared{$ref} = L::VariableNotUsed;
                    if $my.properties<expr> !=== NONE {
                        traverse($my.properties<expr>);
                        %assigned{$ref} = True;
                        if $my.properties<expr>.isa("Q::Identifier") && $my.properties<expr>.properties<name>.value eq $name {
                            @complaints.push: L::RedundantAssignment.new(:$name);
                            %readbeforeassigned{$ref} :delete;
                        }
                    }
                }
                elsif $node.isa("Q::Infix::Assignment") -> $infix {
                    traverse($infix.properties<rhs>);
                    die "LHS was not an identifier"
                        unless $infix.properties<lhs>.isa("Q::Identifier");
                    my $name = $infix.properties<lhs>.properties<name>.value;
                    if $infix.properties<rhs>.isa("Q::Identifier") && $infix.properties<rhs>.properties<name>.value eq $name {
                        @complaints.push: L::RedundantAssignment.new(:$name);
                    }
                    %assigned{ref $name} = True;
                }
                elsif $node.isa("Q::Infix::Addition") -> $infix {
                    traverse($infix.properties<lhs>);
                    traverse($infix.properties<rhs>);
                }
                elsif $node.isa("Q::ParameterList") -> $parameterlist {
                    # nothing
                }
                elsif $node.isa("Q::Literal") -> $literal {
                    # nothing
                }
                elsif $node.isa("Q::Term") -> $term {
                    # nothing
                }
                else {
                    die "Couldn't handle ", $node.type;
                }
            }

            traverse($root);
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
