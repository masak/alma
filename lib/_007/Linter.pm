use _007::Q;

role Lint {
    method message { ... }
}

class L::SubNotUsed does Lint {
    has $.name;
    method message { "Sub '$.name' is declared but never used." }
}

class X::AssertionFailure is Exception {
    has $.message;
    method new($message) { self.bless(:$message) }
}

role _007::Linter {
    has $.parser;

    method lint($program) {
        my %declared;
        my %used;

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

            multi traverse(Q::ParameterList $paramlist) {
            }

            multi traverse(Q::StatementList $stmtlist) {
                for @$stmtlist -> $stmt {
                    traverse($stmt);
                }
            }

            multi traverse(Q::Statement::Sub $sub) {
                my $name = $sub.ident.name;
                %declared{"{@blocks[*-1].WHICH.Str}|$name"} = True;
            }

            multi traverse(Q::Statement::Expr $stexpr) {
                traverse($stexpr.expr);
            }

            multi traverse(Q::Postfix::Call $call) {
                traverse($call.expr);
                traverse($call.argumentlist);
            }

            multi traverse(Q::Identifier $ident) {
                my $name = $ident.name;
                # XXX: what we should really do is whitelist all of he built-ins
                return if $name eq "say";
                for @blocks.reverse -> $block {
                    my $ref = "{$block.WHICH.Str}|$name";
                    my %pad = $block.static-lexpad;
                    if %pad{$name} {
                        %used{$ref} = True;
                        return;
                    }
                }
                die X::AssertionFailure.new("A thing that is used must be declared somewhere");
            }

            multi traverse(Q::ArgumentList $arglist) {
                for @$arglist -> $expr {
                    traverse($expr);
                }
            }

            multi traverse(Q::Literal $literal) {
            }

            multi traverse(Q::Statement::For $for) {
                traverse($for.expr);
                traverse($for.block);
            }
        }

        my @complaints;

        for %declared.keys -> $ref {
            next if %used{$ref};
            my $name = $ref.subst(/^ .* \|/, "");
            @complaints.push: L::SubNotUsed.new(:$name);
        }

        return @complaints;
    }
}
