use _007::Q;

role Lint {
    method message { ... }
}

class L::SubNotUsed does Lint {
    has $.name;
    method message { "Sub '$.name' is declared but never used." }
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
            sub currentblock { @blocks[*-1] }

            multi traverse(Q::Statement::Block $stblock) {
                traverse($stblock.block);
            }

            multi traverse(Q::Block $block) {
                @blocks.push: $block.WHICH.Str;
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
                %declared{"{currentblock}|$name"} = True;
            }

            multi traverse(Q::Statement::Expr $stexpr) {
                traverse($stexpr.expr);
            }

            multi traverse(Q::Postfix::Call $call) {
                traverse($call.expr);
                traverse($call.argumentlist);
            }

            multi traverse(Q::Identifier $ident) {
                # XXX: still not quite there, because variable lookup goes up the OUTER:: chain
                my $name = $ident.name;
                %used{"{currentblock}|$name"} = True;
            }

            multi traverse(Q::ArgumentList $arglist) {
                for @$arglist -> $expr {
                    traverse($expr);
                }
            }

            multi traverse(Q::Literal $literal) {
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
