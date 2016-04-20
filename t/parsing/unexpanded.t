use v6;
use Test;
use _007::Test;

{
    my $program = q:to/./;
        macro moo() {
            return quasi { say("OH HAI"); };
        }

        moo();
        .

    my $ast = q:to/./;
        (statementlist
          (macro (identifier "moo") (block (parameterlist) (statementlist
            (return (quasi "" (postfix:<()> (identifier "say") (argumentlist (str "OH HAI"))))))))
          (stexpr (postfix:<()> (identifier "say") (argumentlist (str "OH HAI")))))
        .

    my $unexpanded-ast = q:to/./;
        (statementlist
          (macro (identifier "moo") (block (parameterlist) (statementlist
            (return (quasi "" (postfix:<()> (identifier "say") (argumentlist (str "OH HAI"))))))))
          (stexpr (postfix:<()> (identifier "moo") (argumentlist))))
        .

    parses-to $program, $ast, "parsing in default (expanded) mode";
    parses-to :unexpanded, $program, $unexpanded-ast, "parsing in unexpanded mode";
}

done-testing;
