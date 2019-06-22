constant __ITSELF__ = {};

class _007::Value {
    has _007::Value $.type;
    has %.slots;

    submethod BUILD(:$type, :%slots) {
        $!type = $type === __ITSELF__
            ?? self
            !! $type;
        %!slots = %slots;
    }

    method Str {
        my %*stringification-seen;
        stringify(self);
    }

    method quoted-Str {
        my %*stringification-seen;
        stringify-quoted(self);
    }

    method attributes { () }

    method truthy { truth-value(self) }
}

class _007::Value::Backed is _007::Value {
    has $.native-value;
}

constant TYPE is export = {};

sub make-type(Str $name, Bool :$backed, :$base = TYPE<Object>) {
    die "base is not defined (declaring {$name})"
        unless $base || $name eq "Object";
    _007::Value.new(:type(TYPE<Type>), slots => { :$name, :$backed, :$base });
}

BEGIN {
    TYPE<Type> = _007::Value.new(:type(__ITSELF__), slots => { name => "Type" });
    TYPE<Object> = make-type "Object";
    {
        # Bootstrap: now that we have Object, let's make it the base of Type and Object
        TYPE<Type>.slots<base> = TYPE<Object>;
        TYPE<Object>.slots<base> = TYPE<Object>;
    }
    # XXX: Should replace the (Perl 6 Bool/Str) values in slots with _007::Value instances

    TYPE<Array> = make-type "Array", :backed;
    TYPE<Bool> = make-type "Bool";
    TYPE<Dict> = make-type "Dict", :backed;
    TYPE<Exception> = make-type "Exception";
    TYPE<Func> = make-type "Func", :backed;
    TYPE<Int> = make-type "Int", :backed;
    TYPE<Macro> = make-type "Macro", :backed;
    TYPE<None> = make-type "None";
    TYPE<Regex> = make-type "Regex";
    TYPE<Str> = make-type "Str", :backed;

    TYPE<Q> = make-type "Q";
    TYPE<Q.ArgumentList> = make-type "Q.ArgumentList", :base(TYPE<Q>);
    TYPE<Q.Block> = make-type "Q.Block", :base(TYPE<Q>);
    TYPE<Q.Declaration> = make-type "Q.Declaration";
    TYPE<Q.Expr> = make-type "Q.Expr", :base(TYPE<Q>);
    TYPE<Q.Expr.BlockAdapter> = make-type "Q.Expr.BlockAdapter", :base(TYPE<Q.Expr>);
    TYPE<Q.Identifier> = make-type "Q.Identifier", :base(TYPE<Q>);
    TYPE<Q.Infix> = make-type "Q.Infix", :base(TYPE<Q.Expr>);
    TYPE<Q.Infix.Assignment> = make-type "Q.Infix.Assignment", :base(TYPE<Q.Infix>);
    TYPE<Q.Infix.Or> = make-type "Q.Infix.Or", :base(TYPE<Q.Infix>);
    TYPE<Q.Infix.DefinedOr> = make-type "Q.Infix.DefinedOr", :base(TYPE<Q.Infix>);
    TYPE<Q.Infix.And> = make-type "Q.Infix.And", :base(TYPE<Q.Infix>);
    TYPE<Q.Term> = make-type "Q.Term", :base(TYPE<Q.Expr>);
    TYPE<Q.Literal> = make-type "Q.Literal", :base(TYPE<Q.Term>);
    TYPE<Q.Literal.None> = make-type "Q.Literal.None", :base(TYPE<Q.Literal>);
    TYPE<Q.Literal.Bool> = make-type "Q.Literal.Bool", :base(TYPE<Q.Literal>);
    TYPE<Q.Literal.Int> = make-type "Q.Literal.Int", :base(TYPE<Q.Literal>);
    TYPE<Q.Literal.Str> = make-type "Q.Literal.Str", :base(TYPE<Q.Literal>);
    TYPE<Q.Property> = make-type "Q.Property", :base(TYPE<Q>);
    TYPE<Q.PropertyList> = make-type "Q.PropertyList", :base(TYPE<Q>);
    TYPE<Q.Regex.Fragment> = make-type "Q.Regex.Fragment";
    TYPE<Q.Regex.Str> = make-type "Q.Regex.Str", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Regex.Identifier> = make-type "Q.Regex.Identifier", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Regex.Call> = make-type "Q.Regex.Call", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Regex.Alternation> = make-type "Q.Regex.Alternation", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Regex.Group> = make-type "Q.Regex.Group", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Regex.OneOrMore> = make-type "Q.Regex.OneOrMore", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Regex.ZeroOrMore> = make-type "Q.Regex.ZeroOrMore", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Regex.ZeroOrOne> = make-type "Q.Regex.ZeroOrOne", :base(TYPE<Q.Regex.Fragment>);
    TYPE<Q.Term.Array> = make-type "Q.Term.Array", :base(TYPE<Q.Term>);
    TYPE<Q.Term.Dict> = make-type "Q.Term.Dict", :base(TYPE<Q.Term>);
    TYPE<Q.Term.Func> = make-type "Q.Term.Func", :base(TYPE<Q.Term>);
    TYPE<Q.Term.Identifier> = make-type "Q.Term.Identifier", :base(TYPE<Q.Identifier>);
    TYPE<Q.Term.Identifier.Direct> = make-type "Q.Term.Identifier.Direct", :base(TYPE<Q.Term.Identifier>);
    TYPE<Q.Term.My> = make-type "Q.Term.My", :base(TYPE<Q.Term>);
    TYPE<Q.Term.Object> = make-type "Q.Term.Object", :base(TYPE<Q.Term>);
    TYPE<Q.Term.Quasi> = make-type "Q.Term.Quasi", :base(TYPE<Q.Term>);
    TYPE<Q.Term.Regex> = make-type "Q.Term.Regex", :base(TYPE<Q.Term>);
    TYPE<Q.Trait> = make-type "Q.Trait", :base(TYPE<Q>);
    TYPE<Q.TraitList> = make-type "Q.TraitList", :base(TYPE<Q>);
    TYPE<Q.Parameter> = make-type "Q.Parameter", :base(TYPE<Q>);
    TYPE<Q.ParameterList> = make-type "Q.ParameterList", :base(TYPE<Q>);
    TYPE<Q.Postfix> = make-type "Q.Postfix", :base(TYPE<Q.Expr>);
    TYPE<Q.Postfix.Index> = make-type "Q.Postfix.Index", :base(TYPE<Q.Postfix>);
    TYPE<Q.Postfix.Call> = make-type "Q.Postfix.Call", :base(TYPE<Q.Postfix>);
    TYPE<Q.Postfix.Property> = make-type "Q.Postfix.Property", :base(TYPE<Q.Postfix>);
    TYPE<Q.Prefix> = make-type "Q.Prefix", :base(TYPE<Q.Expr>);
    TYPE<Q.Statement> = make-type "Q.Statement", :base(TYPE<Q>);
    TYPE<Q.Statement.Expr> = make-type "Q.Statement.Expr", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.If> = make-type "Q.Statement.If", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Block> = make-type "Q.Statement.Block", :base(TYPE<Q.Statement>);
    TYPE<Q.CompUnit> = make-type "Q.CompUnit", :base(TYPE<Q.Statement.Block>);
    TYPE<Q.Statement> = make-type "Q.Statement", :base(TYPE<Q>);
    TYPE<Q.Statement.BEGIN> = make-type "Q.Statement.BEGIN", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Class> = make-type "Q.Statement.Class", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.For> = make-type "Q.Statement.For", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Func> = make-type "Q.Statement.Func", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Macro> = make-type "Q.Statement.Macro", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.While> = make-type "Q.Statement.While", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Return> = make-type "Q.Statement.Return", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Throw> = make-type "Q.Statement.Throw", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Next> = make-type "Q.Statement.Next", :base(TYPE<Q.Statement>);
    TYPE<Q.Statement.Last> = make-type "Q.Statement.Last", :base(TYPE<Q.Statement>);
    TYPE<Q.StatementList> = make-type "Q.StatementList", :base(TYPE<Q>);
    TYPE<Q.Unquote> = make-type "Q.Unquote", :base(TYPE<Q>);
    TYPE<Q.Unquote.Prefix> = make-type "Q.Unquote.Prefix", :base(TYPE<Q.Unquote>);
    TYPE<Q.Unquote.Infix> = make-type "Q.Unquote.Infix", :base(TYPE<Q.Unquote>);
}

# XXX: Not using &is-type in the `where` clause because that leads to a circularity.
# At some point we'll actually want subtypes of TYPE<Type> to be allowable as type
# objects, and then we'll want something like that to actually work.
sub is-instance(_007::Value $v, _007::Value $type where { .type === TYPE<Type> }) is export {
    my $t = $v.type;
    until $t === $type | TYPE<Object> {
        $t = $t.slots<base>;
    }
    return $t === $type;
}

sub is-type($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Type>);
}

sub make-object() is export {
    _007::Value.new(:type(TYPE<Object>));
}

sub is-object($v) is export {
    # is-instance($v, TYPE<Object>) is tautological,
    # but we're consistent and make the right check
    $v ~~ _007::Value && is-instance($v, TYPE<Object>);
}

sub make-array(Array $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Array>), :$native-value);
}

sub is-array($v) is export {
    $v ~~ _007::Value::Backed && is-instance($v, TYPE<Array>);
}

sub get-array-element($v, Int $i) is export {
    $v.native-value[$i];
}

sub set-array-element($v, Int $i, $new-value) is export {
    $v.native-value[$i] = $new-value;
}

sub get-all-array-elements($v) is export {
    $v.native-value;
}

sub get-array-length($v) is export {
    $v.native-value.elems;
}

constant FALSE is export = _007::Value.new(:type(TYPE<Bool>));
constant TRUE is export = _007::Value.new(:type(TYPE<Bool>));

sub make-bool(Bool $value) is export {
    $value ?? TRUE !! FALSE;
}

sub is-bool($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Bool>);
}

sub make-dict(@properties = []) is export {
    my %native-value;
    for @properties -> $p {
        %native-value{$p.key} = $p.value;
    }
    _007::Value::Backed.new(:type(TYPE<Dict>), :%native-value);
}

sub is-dict($v) is export {
    $v ~~ _007::Value::Backed && is-instance($v, TYPE<Dict>);
}

sub get-dict-property($v, Str $key) is export {
    $v.native-value{$key};
}

sub set-dict-property($v, Str $key, $new-value) is export {
    $v.native-value{$key} = $new-value;
}

sub dict-property-exists($v, Str $key) is export {
    $v.native-value{$key} :exists;
}

sub get-all-dict-properties($v) is export {
    my %h := $v.native-value;
    %h.keys.map({ $_ => %h{$_} }).Array;
}

sub get-all-dict-keys($v) is export {
    my %h := $v.native-value;
    %h.keys;
}

sub get-dict-size($v) is export {
    $v.native-value.elems;
}

sub make-exception(_007::Value $message where &is-str) is export {
    _007::Value.new(:type(TYPE<Exception>), slots => { :$message });
}

sub is-exception($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Exception>);
}

multi make-func(
    _007::Value $name where &is-str,
    $parameterlist where &is-q-parameterlist,
    $statementlist where &is-q-statementlist,
    $outer-frame,
    $static-lexpad = make-dict()
) is export {
    _007::Value.new(:type(TYPE<Func>), slots => {
        :$name,
        :$parameterlist,
        :$statementlist,
        :$outer-frame,
        :$static-lexpad,
    });
}

multi make-func(&fn, Str $name, @parameters) is export {
    _007::Value::Backed.new(:type(TYPE<Func>), native-value => [&fn, $name, @parameters]);
}

sub is-func($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Func>);
}

sub make-int(Int $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Int>), :$native-value);
}

sub is-int($v) is export {
    $v ~~ _007::Value::Backed && is-instance($v, TYPE<Int>);
}

sub make-macro(
    _007::Value $name where &is-str,
    $parameterlist where &is-q-parameterlist,
    $statementlist where &is-q-statementlist,
    $outer-frame,
    $static-lexpad = make-dict()
) is export {
    _007::Value.new(:type(TYPE<Macro>), slots => {
        :$name,
        :$parameterlist,
        :$statementlist,
        :$outer-frame,
        :$static-lexpad,
    });
}

sub is-macro($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Macro>);
}

sub is-callable($v) is export {
    is-func($v) || is-macro($v);
}

constant NONE is export = _007::Value.new(:type(TYPE<None>));

sub make-none() is export {
    NONE;
}

sub is-none($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<None>);
}

sub make-regex(
    $contents where &is-q-regex-fragment,
) is export {
    _007::Value.new(:type(TYPE<Regex>), slots => {
        :$contents,
    });
}

sub is-regex($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Regex>);
}

sub regex-parse(Str $str, $fragment, Int $last-index is copy) {
    when &is-q-regex-str($fragment) {
        my $value = $fragment.contents.native-value;
        my $slice = $str.substr($last-index, $value.chars);
        return Nil if $slice ne $value;
        return $last-index + $value.chars;
    }
    #when &is-q-regex-identifier($fragment) {
    #    die "Unhandled regex fragment";
    #}
    #when &is-q-regex-call($fragment) {
    #    die "Unhandled regex fragment";
    #}
    when is-q-regex-group($fragment) {
        for $fragment.fragments -> $group-fragment {
            with regex-parse($str, $group-fragment, $last-index) {
                $last-index = $_;
            } else {
                return Nil;
            }
        }
        return $last-index;
    }
    when is-q-regex-zeroorone($fragment) {
        with regex-parse($str, $fragment.fragment, $last-index) {
            return $_;
        } else {
            return $last-index;
        }
    }
    when is-q-regex-oneormore($fragment) {
        # XXX technically just a fragment+a ZeroOrMore
        return Nil unless $last-index = regex-parse($str, $fragment.fragment, $last-index);
        loop {
            with regex-parse($str, $fragment.fragment, $last-index) {
                $last-index = $_;
            } else {
                last;
            }
        }
        return $last-index;
    }
    when is-q-regex-zeroormore($fragment) {
        loop {
            with regex-parse($str, $fragment.fragment, $last-index) {
                $last-index = $_;
            } else {
                last;
            }
        }
        return $last-index;
    }
    when is-q-regex-alternation($fragment) {
        for $fragment.alternatives -> $alternative {
            with regex-parse($str, $alternative, $last-index) {
                return $_;
            }
        }
        return Nil;
    }
    default {
        die "No handler for {$fragment.^name}";
    }
}

sub regex-fullmatch(_007::Value $regex where &is-regex, Str $str) is export {
    return ?($_ == $str.chars with regex-parse($str, $regex.slots<contents>, 0));
}

sub regex-search(_007::Value $regex where &is-regex, Str $str) is export {
    for ^$str.chars {
        return True
            with regex-parse($str, $regex.slots<contents>, $_);
    }
    return False;
}

sub make-str(Str $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Str>), :$native-value);
}

sub is-str($v) is export {
    $v ~~ _007::Value::Backed && is-instance($v, TYPE<Str>);
}

sub is-q($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q>);
}

sub make-q-argumentlist(
    _007::Value $arguments where &is-array = make-array([])
) is export {
    _007::Value.new(:type(TYPE<Q.ArgumentList>), slots => {
        :$arguments,
    });
}

sub is-q-argumentlist($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.ArgumentList>);
}

sub make-q-block(
    _007::Value $parameterlist where &is-q-parameterlist,
    _007::Value $statementlist where &is-q-statementlist,
    _007::Value $static-lexpad where &is-dict = make-dict(),
) is export {
    _007::Value.new(:type(TYPE<Q.Block>), slots => {
        :$parameterlist,
        :$statementlist,
        :$static-lexpad,
    });
}

sub is-q-block($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Block>);
}

sub set-q-block-static-lexpad(
    _007::Value $q-block where &is-q-block,
    _007::Value $static-lexpad where &is-dict,
) is export {
    $q-block.slot<static-lexpad> = $static-lexpad;
}

sub is-q-expr($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Expr>);
}

sub make-q-expr-blockadapter(
    _007::Value $block where &is-q-block
) is export {
    _007::Value.new(:type(TYPE<Q.Expr.BlockAdapter>), slots => {
        :$block,
    });
}

sub is-q-expr-blockadapter($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Expr>);
}

sub make-q-identifier(_007::Value $name where &is-str) is export {
    _007::Value.new(:type(TYPE<Q.Identifier>), slots => {
        :$name,
    });
}

sub is-q-identifier($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Identifier>);
}

sub make-q-infix(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $lhs where &is-q-expr,
    _007::Value $rhs where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Infix>), slots => {
        :$identifier,
        :$lhs,
        :$rhs,
    });
}

sub is-q-infix($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Infix>);
}

sub make-q-infix-assignment(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $lhs where &is-q-expr,
    _007::Value $rhs where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Infix.Assignment>), slots => {
        :$identifier,
        :$lhs,
        :$rhs,
    });
}

sub is-q-infix-assignment($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Infix.Assignment>);
}

sub make-q-infix-or(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $lhs where &is-q-expr,
    _007::Value $rhs where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Infix.Or>), slots => {
        :$identifier,
        :$lhs,
        :$rhs,
    });
}

sub is-q-infix-or($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Infix.Or>);
}

sub make-q-infix-definedor(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $lhs where &is-q-expr,
    _007::Value $rhs where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Infix.DefinedOr>), slots => {
        :$identifier,
        :$lhs,
        :$rhs,
    });
}

sub is-q-infix-definedor($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Infix.DefinedOr>);
}

sub make-q-infix-and(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $lhs where &is-q-expr,
    _007::Value $rhs where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Infix.And>), slots => {
        :$identifier,
        :$lhs,
        :$rhs,
    });
}

sub is-q-infix-and($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Infix.And>);
}

sub make-q-literal-none() is export {
    _007::Value.new(:type(TYPE<Q.Literal.None>));
}

sub is-q-literal-none($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Literal.None>);
}

sub make-q-literal-bool(
    _007::Value $value where &is-bool
) is export {
    _007::Value.new(:type(TYPE<Q.Literal.None>), slots => {
        :$value,
    });
}

sub is-q-literal-bool($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Literal.Bool>);
}

sub make-q-literal-int(
    _007::Value $value where &is-int
) is export {
    _007::Value.new(:type(TYPE<Q.Literal.Int>), slots => {
        :$value,
    });
}

sub is-q-literal-int($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Literal.Int>);
}

sub make-q-literal-str(
    _007::Value $value where &is-str
) is export {
    _007::Value.new(:type(TYPE<Q.Literal.Str>), slots => {
        :$value,
    });
}

sub is-q-literal-str($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Literal.Str>);
}

sub make-q-property(
    _007::Value $key where &is-str,
    _007::Value $value where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Property>), slots => {
        :$key,
        :$value,
    });
}

sub is-q-property($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Property>);
}

sub make-q-propertylist(
    _007::Value $properties where &is-array
) is export {
    _007::Value.new(:type(TYPE<Q.PropertyList>), slots => {
        :$properties,
    });
}

sub is-q-propertylist($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.PropertyList>);
}

sub is-q-regex-fragment($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.Fragment>);
}

sub make-q-regex-str(
    _007::Value $contents where &is-str
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.Str>), slots => {
        :$contents,
    });
}

sub is-q-regex-str($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.Str>);
}

sub make-q-regex-identifier(
    _007::Value $identifier where &is-q-identifier
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.Identifier>), slots => {
        :$identifier,
    });
}

sub is-q-regex-identifier($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.Identifier>);
}

sub make-q-regex-call(
    _007::Value $identifier where &is-q-identifier
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.Call>), slots => {
        :$identifier,
    });
}

sub is-q-regex-call($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.Call>);
}

sub make-q-regex-alternation(
    _007::Value $alternatives where &is-array
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.Alternation>), slots => {
        :$alternatives,
    });
}

sub is-q-regex-alternation($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.Alternation>);
}

sub make-q-regex-group(
    _007::Value $fragments where &is-array
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.Group>), slots => {
        :$fragments,
    });
}

sub is-q-regex-group($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.Group>);
}

sub make-q-regex-oneormore(
    _007::Value $fragment where &is-q-regex-fragment
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.OneOrMore>), slots => {
        :$fragment,
    });
}

sub is-q-regex-oneormore($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.OneOrMore>);
}

sub make-q-regex-zeroormore(
    _007::Value $fragment where &is-q-regex-fragment
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.ZeroOrMore>), slots => {
        :$fragment,
    });
}

sub is-q-regex-zeroormore($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.ZeroOrMore>);
}

sub make-q-regex-zeroorone(
    _007::Value $fragment where &is-q-regex-fragment
) is export {
    _007::Value.new(:type(TYPE<Q.Regex.ZeroOrNone>), slots => {
        :$fragment,
    });
}

sub is-q-regex-zeroorone($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Regex.ZeroOrOne>);
}

sub make-q-term-array(
    _007::Value $elements where &is-array
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Array>), slots => {
        :$elements,
    });
}

sub is-q-term-array($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Array>);
}

sub make-q-term-dict(
    _007::Value $propertylist where &is-q-propertylist
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Dict>), slots => {
        :$propertylist,
    });
}

sub is-q-term-dict($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Dict>);
}

sub make-q-term-func(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $traitlist where &is-q-traitlist,
    _007::Value $block where &is-q-block,
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Func>), slots => {
        :$identifier,
        :$traitlist,
        :$block,
    });
}

sub is-q-term-func($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Func>);
}

sub make-q-term-identifier(
    _007::Value $name where &is-str
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Identifier>), slots => {
        :$name,
    });
}

sub is-q-term-identifier($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Identifier>);
}

sub make-q-term-identifier-direct(
    _007::Value $name where &is-str,
    _007::Value $frame where &is-dict,
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Identifier.Direct>), slots => {
        :$name,
        :$frame,
    });
}

sub is-q-term-identifier-direct($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Identifier.Direct>);
}

sub make-q-term-my(
    _007::Value $identifier where &is-q-identifier,
) is export {
    _007::Value.new(:type(TYPE<Q.Term.My>), slots => {
        :$identifier,
    });
}

sub is-q-term-my($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.My>);
}

subset ToV of Any where { $_ ~~ Val::Type || is-type($_) }

sub make-q-term-object(
    ToV $type,
    _007::Value $propertylist where &is-q-propertylist,
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Object>), slots => {
        :$type,
        :$propertylist,
    });
}

sub is-q-term-object($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Object>);
}

sub make-q-term-quasi(
    _007::Value $qtype where &is-str,
    _007::Value $contents where &is-q,
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Quasi>), slots => {
        :$qtype,
        :$contents,
    });
}

sub is-q-term-quasi($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Quasi>);
}

sub make-q-term-regex(
    _007::Value $contents where &is-q-regex-fragment
) is export {
    _007::Value.new(:type(TYPE<Q.Term.Regex>), slots => {
        :$contents,
    });
}

sub is-q-term-regex($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Term.Regex>);
}

sub make-q-trait(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $expr where &is-q-expr,
) is export {
}

sub is-q-trait($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Trait>);
}

sub make-q-traitlist(
    _007::Value $traits where &is-array = make-array([])
) is export {
    _007::Value.new(:type(TYPE<Q.TraitList>), slots => {
        :$traits,
    });
}

sub is-q-traitlist($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.TraitList>);
}

sub make-q-parameter(
    _007::Value $identifier where &is-q-identifier
) is export {
    _007::Value.new(:type(TYPE<Q.Parameter>), slots => {
        :$identifier,
    });
}

sub is-q-parameter($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Parameter>);
}

sub make-q-parameterlist(
    _007::Value $parameters where &is-array = make-array([])
) is export {
    _007::Value.new(:type(TYPE<Q.ParameterList>), slots => {
        :$parameters,
    });
}

sub is-q-parameterlist($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.ParameterList>);
}

sub make-q-postfix(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $operand where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Postfix>), slots => {
        :$identifier,
        :$operand,
    });
}

sub is-q-postfix($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Postfix>);
}

sub make-q-postfix-index(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $operand where &is-q-expr,
    _007::Value $index where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Postfix.Index>), slots => {
        :$identifier,
        :$operand,
        :$index,
    });
}

sub is-q-postfix-index($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Postfix.Index>);
}

sub make-q-postfix-call(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $operand where &is-q-expr,
    _007::Value $argumentlist where &is-q-argumentlist,
) is export {
    _007::Value.new(:type(TYPE<Q.Postfix.Call>), slots => {
        :$identifier,
        :$operand,
        :$argumentlist,
    });
}

sub is-q-postfix-call($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Postfix.Call>);
}

sub make-q-postfix-property(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $operand where &is-q-expr,
    _007::Value $property where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Postfix.Property>), slots => {
        :$identifier,
        :$operand,
        :$property,
    });
}

sub is-q-postfix-property($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Postfix.Property>);
}

sub make-q-prefix(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $operand where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Prefix>), slots => {
        :$identifier,
        :$operand,
    });
}

sub is-q-prefix($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Prefix>);
}

sub make-q-statement-expr(
    _007::Value $expr where &is-q-expr
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.Expr>), slots => {
        :$expr,
    });
}

sub is-q-statement-expr($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.Expr>);
}

sub make-q-statement-if(
    _007::Value $expr where &is-q-expr,
    _007::Value $block where &is-q-block,
    _007::Value $else where &is-q = NONE,
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.If>), slots => {
        :$expr,
        :$block,
        :$else,
    });
}

sub is-q-statement-if($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.If>);
}

sub make-q-statement-block(
    _007::Value $block where &is-q-block
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.Block>), slots => {
        :$block,
    });
}

sub is-q-statement-block($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.Block>);
}

sub make-q-compunit(
    _007::Value $block where &is-q-block
) is export {
    _007::Value.new(:type(TYPE<Q.CompUnit>), slots => {
        :$block,
    });
}

sub is-q-compunit($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.CompUnit>);
}

sub make-q-statement-begin(
    _007::Value $block where &is-q-block
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.BEGIN>), slots => {
        :$block,
    });
}

sub is-q-statement-begin($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.BEGIN>);
}

sub make-q-statement-class(_007::Value $block where &is-q-block) is export {
    _007::Value.new(:type(TYPE<Q.Statement.Class>), slots => {
        :$block,
    });
}

sub is-q-statement-class($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.Class>);
}

sub make-q-statement-for(
    _007::Value $expr where &is-q-expr,
    _007::Value $block where &is-q-block,
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.For>), slots => {
        :$expr,
        :$block,
    });
}

sub is-q-statement-for($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.For>);
}

sub make-q-statement-func(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $traitlist where &is-q-traitlist,
    _007::Value $block where &is-q-block,
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.Func>), slots => {
        :$identifier,
        :$traitlist,
        :$block,
    });
}

sub is-q-statement-func($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.Func>);
}

sub make-q-statement-macro(
    _007::Value $identifier where &is-q-identifier,
    _007::Value $traitlist where &is-q-traitlist,
    _007::Value $block where &is-q-block,
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.Macro>), slots => {
        :$identifier,
        :$traitlist,
        :$block,
    });
}

sub is-q-statement-macro($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.Macro>);
}

sub make-q-statement-while(
    _007::Value $expr where &is-q-expr,
    _007::Value $block where &is-q-block,
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.While>), slots => {
        :$expr,
        :$block,
    });
}

sub is-q-statement-while($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.While>);
}

sub make-q-statement-return(
    _007::Value $expr where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.Return>), slots => {
        :$expr,
    });
}

sub is-q-statement-return($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.Return>);
}

sub make-q-statement-throw(
    _007::Value $expr where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Statement.Throw>), slots => {
        :$expr,
    });
}

sub is-q-statement-throw($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Statement.Throw>);
}

sub make-q-statementlist(
    _007::Value $statements where &is-array = make-array([])
) is export {
    _007::Value.new(:type(TYPE<Q.StatementList>), slots => {
        :$statements,
    });
}

sub is-q-statementlist($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.StatementList>);
}

sub make-q-unquote(
    _007::Value $qtype where &is-str,
    _007::Value $expr where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Unquote>), slots => {
        :$qtype,
        :$expr,
    });
}

sub is-q-unquote($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Unquote>);
}

sub make-q-unquote-prefix(
    _007::Value $qtype where &is-str,
    _007::Value $expr where &is-q-expr,
    _007::Value $operand where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Unquote.Prefix>), slots => {
        :$qtype,
        :$expr,
        :$operand,
    });
}

sub is-q-unquote-prefix($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Unquote.Prefix>);
}

sub make-q-unquote-infix(
    _007::Value $qtype where &is-str,
    _007::Value $expr where &is-q-expr,
    _007::Value $lhs where &is-q-expr,
    _007::Value $rhs where &is-q-expr,
) is export {
    _007::Value.new(:type(TYPE<Q.Unquote.Infix>), slots => {
        :$qtype,
        :$expr,
        :$lhs,
        :$rhs,
    });
}

sub is-q-unquote-infix($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Q.Unquote.Infix>);
}

sub is-q-declaration($v) is export {
    # XXX
    False;
}

sub escaped-name($func) is export {
    sub escape-backslashes($s) { $s.subst(/\\/, "\\\\", :g) }
    sub escape-less-thans($s) { $s.subst(/"<"/, "\\<", :g) }

    my $name = $func ~~ _007::Value::Backed
        ?? $func.native-value[1]
        !! $func.slots<name>.native-value;

    return $name
        unless $name ~~ /^ (prefix | infix | postfix) ':' (.+) /;

    return "{$0}:<{escape-less-thans escape-backslashes $1}>"
        if $1.contains(">") && $1.contains("»");

    return "{$0}:«{escape-backslashes $1}»"
        if $1.contains(">");

    return "{$0}:<{escape-backslashes $1}>";
}

sub pretty-parameters($func) {
    my @parameters = $func ~~ _007::Value::Backed
        ?? @($func.native-value[2])
        !! get-all-array-elements($func.slots<parameterlist>.parameters);
    sprintf "(%s)", @parameters».identifier».name.join(", ");
}

sub stringify(_007::Value $value) {
    if $value.type === TYPE<Array> {
        if %*stringification-seen{$value.WHICH}++ {
            return "[...]";
        }
        return "[" ~ get-all-array-elements($value).map({
            $_ ~~ _007::Value ?? stringify-quoted($_) !! .quoted-Str
        }).join(', ') ~ "]";
    }
    elsif $value.type === TYPE<Dict> {
        if %*stringification-seen{$value.WHICH}++ {
            return "\{...\}";
        }
        return '{' ~ get-all-dict-properties($value).map({
            my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                ?? .key
                !! make-str(.key).quoted-Str;
            "{$key}: {.value ~~ _007::Value ?? stringify-quoted(.value) !! .value.quoted-Str}"
        }).sort.join(', ') ~ '}';
    }
    elsif $value ~~ _007::Value::Backed && $value.type === TYPE<Func> {
        return "<func {escaped-name($value)}{pretty-parameters($value)}>";
    }
    elsif $value ~~ _007::Value::Backed && $value.type === TYPE<Macro> {
        return "<macro {escaped-name($value)}{pretty-parameters($value)}>";
    }
    elsif $value ~~ _007::Value::Backed {
        return ~$value.native-value;
    }
    elsif $value.type === TYPE<Bool> {
        return $value === TRUE
            ?? "true"
            !! "false";
    }
    elsif $value.type === TYPE<Func> {
        return "<func {escaped-name($value)}{pretty-parameters($value)}>";
    }
    elsif $value.type === TYPE<Macro> {
        return "<macro {escaped-name($value)}{pretty-parameters($value)}>";
    }
    elsif $value.type === TYPE<None> {
        return "none";
    }
    elsif $value.type === TYPE<Object> {
        return "<object>";
    }
    elsif $value.type === TYPE<Type> {
        return "<type {$value.slots<name>}>";
    }
    else {
        die "Unknown _007::Value type sent to stringify: ", $value.type.slots<name>;
    }
}

sub stringify-quoted(_007::Value $value) {
    if is-str($value) {
        return q["] ~ $value.native-value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["];
    }
    return stringify($value);
}

sub truth-value(_007::Value $value) {
    is-func($value) || is-macro($value) || ($value ~~ _007::Value::Backed
        ?? ?$value.native-value
        !! !is-none($value) && !is-bool($value) || $value === TRUE);
}
