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

            multi traverse(Q::Statement::Block $stblock) {
                traverse($stblock.block);
            }

            multi traverse(Q::Block $block) {
                traverse($block.parameterlist);
                traverse($block.statementlist);
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
                %declared{$name} = True;
            }

            multi traverse(Q::Statement::Expr $stexpr) {
                traverse($stexpr.expr);
            }

            multi traverse(Q::Postfix::Call $call) {
                traverse($call.expr);
                traverse($call.argumentlist);
            }

            multi traverse(Q::Identifier $ident) {
                # XXX: it's actually more intricate than this, due to block scoping
                my $name = $ident.name;
                %used{$name} = True;
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

        for %declared.keys -> $name {
            next if %used{$name};
            @complaints.push: L::SubNotUsed.new(:$name);
        }

        return @complaints;
    }
}
