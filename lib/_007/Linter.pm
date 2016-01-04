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

            multi traverse(Q::Statement::Block $stblock) {
                traverse($stblock.block);
            }

            multi traverse(Q::Block $block) {
                @blocks.push: $block;
                traverse($block.parameterlist);
                traverse($block.statementlist);
                @blocks.pop;
            }

            multi traverse(Q::ParameterList $parameterlist) {
            }

            multi traverse(Q::StatementList $statementlist) {
                for $statementlist.statements.elements -> $stmt {
                    traverse($stmt);
                }
            }

            multi traverse(Q::Statement::Sub $sub) {
                my $name = $sub.identifier.name;
                %declared{"{@blocks[*-1].WHICH.Str}|$name"} = L::SubNotUsed;
            }

            multi traverse(Q::Statement::Expr $stexpr) {
                traverse($stexpr.expr);
            }

            multi traverse(Q::Postfix::Call $call) {
                traverse($call.operand);
                traverse($call.argumentlist);
            }

            sub ref($name) {
                for @blocks.reverse -> $block {
                    my %pad = $block.static-lexpad;
                    if %pad{$name} {
                        return "{$block.WHICH.Str}|$name";
                    }
                }
                fail X::AssertionFailure.new("A thing that is used must be declared somewhere");
            }

            multi traverse(Q::Identifier $identifier) {
                my $name = $identifier.name;
                # XXX: what we should really do is whitelist all of he built-ins
                return if $name eq "say";
                my $ref = ref $name;

                %used{ref $name} = True;
                if !%assigned{ref $name} {
                    %readbeforeassigned{$ref} = True;
                }
            }

            multi traverse(Q::ArgumentList $argumentlist) {
                for $argumentlist.arguments.elements -> $expr {
                    traverse($expr);
                }
            }

            multi traverse(Q::Literal $literal) {
            }

            multi traverse(Q::Term $term) {
            }

            multi traverse(Q::Statement::For $for) {
                traverse($for.expr);
                traverse($for.block);
            }

            multi traverse(Q::Statement::My $my) {
                my $name = $my.identifier.name;
                my $ref = "{@blocks[*-1].WHICH.Str}|$name";
                %declared{$ref} = L::VariableNotUsed;
                if $my.expr !~~ Val::None {
                    traverse($my.expr);
                    %assigned{$ref} = True;
                    if $my.expr ~~ Q::Identifier && $my.expr.name eq $name {
                        @complaints.push: L::RedundantAssignment.new(:$name);
                        %readbeforeassigned{$ref} :delete;
                    }
                }
            }

            multi traverse(Q::Infix::Assignment $infix) {
                traverse($infix.rhs);
                die "LHS was not an identifier"
                    unless $infix.lhs ~~ Q::Identifier;
                my $name = $infix.lhs.name;
                if $infix.rhs ~~ Q::Identifier && $infix.rhs.name eq $name {
                    @complaints.push: L::RedundantAssignment.new(:$name);
                }
                %assigned{ref $name} = True;
            }

            multi traverse(Q::Infix::Addition $infix) {
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
