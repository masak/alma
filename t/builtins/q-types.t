use _007::Builtins;
use Test;
use _007::Test;

my @q-types = <
    Q
    Q.Identifier
    Q.Expr
    Q.Term
    Q.Literal
    Q.Literal.None
    Q.Literal.Bool
    Q.Literal.Int
    Q.Literal.Str
    Q.Term.Identifier
    Q.Term.Identifier.Direct
    Q.Regex.Fragment
    Q.Regex.Str
    Q.Regex.Identifier
    Q.Regex.Call
    Q.Regex.Alternation
    Q.Regex.Group
    Q.Regex.OneOrMore
    Q.Regex.ZeroOrMore
    Q.Regex.ZeroOrOne
    Q.Term.Regex
    Q.Term.Array
    Q.Term.Object
    Q.Term.Dict
    Q.Property
    Q.PropertyList
    Q.Declaration
    Q.Trait
    Q.TraitList
    Q.Term.Func
    Q.Block
    Q.Prefix
    Q.Infix
    Q.Infix.Assignment
    Q.Infix.Or
    Q.Infix.DefinedOr
    Q.Infix.And
    Q.Postfix
    Q.Postfix.Index
    Q.Postfix.Call
    Q.Postfix.Property
    Q.Unquote
    Q.Unquote.Prefix
    Q.Unquote.Infix
    Q.Term.My
    Q.Term.Quasi
    Q.Parameter
    Q.ParameterList
    Q.ArgumentList
    Q.Statement
    Q.Statement.Expr
    Q.Statement.If
    Q.Statement.Block
    Q.CompUnit
    Q.Statement.For
    Q.Statement.While
    Q.Statement.Return
    Q.Statement.Throw
    Q.Statement.Func
    Q.Statement.Macro
    Q.Statement.BEGIN
    Q.Statement.Class
    Q.StatementList
    Q.Expr.BlockAdapter
>;

for @q-types -> $q-type {
    my $program = qq:to/./;
        say({$q-type});
        .

    outputs $program, "<type {$q-type}>\n", "can access {$q-type}";
}

done-testing;
