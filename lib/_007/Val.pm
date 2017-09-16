use MONKEY-SEE-NO-EVAL;

class X::Uninstantiable is Exception {
    has Str $.name;

    method message() { "<type {$.name}> is abstract and uninstantiable"; }
}

class X::Property::NotDeclared is Exception {
    has Str $.type;
    has Str $.property;

    method message { "The property '$.property' is not defined on type '$.type'" }
}

class X::Property::Required is Exception {
    has Str $.type;
    has Str $.property;

    method message { "The property '$.property' is required on type '$.type'" }
}

class X::Property::Duplicate is Exception {
    has Str $.property;

    method message { "The property '$.property' was declared more than once in a property list" }
}

class X::Control::Return is Exception {
    has $.frame;
    has $.value;
}

class X::_007::RuntimeException is Exception {
    has $.msg;

    method message {
        $.msg.Str;
    }
}

class X::Subscript::TooLarge is Exception {
    has $.value;
    has $.length;

    method message() { "Subscript ($.value) too large (array length $.length)" }
}

class X::Subscript::NonInteger is Exception {
}

class X::Subscript::NonString is Exception {
}

class X::ParameterMismatch is Exception {
    has $.type;
    has $.paramcount;
    has $.argcount;

    method message {
        "$.type with $.paramcount parameters called with $.argcount arguments"
    }
}

class Helper { ... }
class _007::Object { ... }

sub unique-id { ++$ }

constant TYPE = hash();

class _007::Type {
    has Str $.name;
    has $.base = TYPE<Object>;
    has @.fields;
    has Bool $.is-abstract = False;
    # XXX: $.id

    method install-base($none) {
        $!base = $none;
    }

    method type-chain() {
        my @chain;
        my $t = self;
        while $t ~~ _007::Type {
            @chain.push($t);
            $t.=base;
        }
        return @chain;
    }

    method attributes { () }

    method quoted-Str { self.Str }
    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }

    method create(*%properties) {
        die X::Uninstantiable.new(:$.name)
            if self.is-abstract;

        # XXX: For Dict and Array, we might instead want to do a shallow copy
        if self === TYPE<Dict> || self === TYPE<Array> || self === TYPE<Int> || self === TYPE<Str> {
            return %properties<value>;
        }

        if self === TYPE<Type> {
            return _007::Type.new(
                :name(%properties<name> ?? %properties<name>.value !! ""),
                :base(%properties<base> // TYPE<Object>),
                :fields(%properties<fields> ?? %properties<fields>.value !! []),
                :is-abstract(%properties<is-abstract> // False),
            );
        }

        my $type = $.name;
        my $fields = set(self.type-chain.map({ .fields }));
        my $seen = set();
        for %properties.keys.sort -> $property {
            die X::Property::NotDeclared.new(:$type, :$property)
                unless $property (elem) $fields;

            die X::Property::Duplicate.new(:$type, :$property)
                if $property (elem) $seen;

            $seen (|)= $property;
        }
        # XXX: need to screen for required properties by traversing @.fields, but we don't have the
        #      infrastructure in terms of a way to mark up a field as required

        # XXX: for now, let's pretend all properties are required. not pleasant, but we can live with it for a short time
        for $fields.keys -> $field {
            die "Need to pass property '$field' when creating a $type"
                unless $field (elem) $seen;
        }

        # XXX: ditto for property default values

        return _007::Object.new(:type(self), :%properties);
    }
}

BEGIN {
    for <Object Type NoneType Bool> -> $name {
        TYPE{$name} = _007::Type.new(:$name);
    }
}
for <Int Str Array Dict> -> $name {
    TYPE{$name} = _007::Type.new(:$name);
}
TYPE<Exception> = _007::Type.new(:name<Exception>, :fields["message"]);
TYPE<Sub> = _007::Type.new(:name<Sub>, :fields["name", "parameterlist", "statementlist", "static-lexpad", "outer-frame"]);
TYPE<Macro> = _007::Type.new(:name<Macro>, :base(TYPE<Sub>));
TYPE<Regex> = _007::Type.new(:name<Regex>, :fields["contents"]);

TYPE<Q> = _007::Type.new(:name<Q>, :is-abstract);
TYPE<Q::Literal> = _007::Type.new(:name<Q::Literal>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Literal::None> = _007::Type.new(:name<Q::Literal::None>, :base(TYPE<Q::Literal>));
TYPE<Q::Literal::Bool> = _007::Type.new(:name<Q::Literal::Bool>, :base(TYPE<Q::Literal>), :fields["value"]);
TYPE<Q::Literal::Int> = _007::Type.new(:name<Q::Literal::Int>, :base(TYPE<Q::Literal>), :fields["value"]);
TYPE<Q::Literal::Str> = _007::Type.new(:name<Q::Literal::Str>, :base(TYPE<Q::Literal>), :fields["value"]);
TYPE<Q::Term> = _007::Type.new(:name<Q::Term>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Term::Dict> = _007::Type.new(:name<Q::Term::Dict>, :base(TYPE<Q::Term>), :fields["propertylist"]);
TYPE<Q::Term::Object> = _007::Type.new(:name<Q::Term::Object>, :base(TYPE<Q::Term>), :fields["type", "propertylist"]);
TYPE<Q::Term::Sub> = _007::Type.new(:name<Q::Term::Sub>, :base(TYPE<Q::Term>), :fields["identifier", "traitlist", "block"]);
TYPE<Q::Term::Quasi> = _007::Type.new(:name<Q::Term::Quasi>, :base(TYPE<Q::Term>), :fields["qtype", "contents"]);
TYPE<Q::Term::Array> = _007::Type.new(:name<Q::Term::Array>, :base(TYPE<Q::Term>), :fields["elements"]);
TYPE<Q::Term::Regex> = _007::Type.new(:name<Q::Term::Regex>, :base(TYPE<Q::Term>), :fields["contents"]);
TYPE<Q::Identifier> = _007::Type.new(:name<Q::Identifier>, :base(TYPE<Q>), :fields["name", "frame"]);
TYPE<Q::Block> = _007::Type.new(:name<Q::Block>, :base(TYPE<Q>), :fields["parameterlist", "statementlist", "static-lexpad"]);
TYPE<Q::Expr> = _007::Type.new(:name<Q::Expr>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Prefix> = _007::Type.new(:name<Q::Prefix>, :base(TYPE<Q::Expr>), :fields["identifier", "operand"]);
TYPE<Q::Prefix::Str> = _007::Type.new(:name<Q::Prefix::Str>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Plus> = _007::Type.new(:name<Q::Prefix::Plus>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Minus> = _007::Type.new(:name<Q::Prefix::Minus>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::So> = _007::Type.new(:name<Q::Prefix::So>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Not> = _007::Type.new(:name<Q::Prefix::Not>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Upto> = _007::Type.new(:name<Q::Prefix::Upto>, :base(TYPE<Q::Prefix>));
TYPE<Q::Infix> = _007::Type.new(:name<Q::Infix>, :base(TYPE<Q::Expr>), :fields["identifier", "lhs", "rhs"]);
TYPE<Q::Infix::Addition> = _007::Type.new(:name<Q::Infix::Addition>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Subtraction> = _007::Type.new(:name<Q::Infix::Subtraction>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Multiplication> = _007::Type.new(:name<Q::Infix::Multiplication>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Modulo> = _007::Type.new(:name<Q::Infix::Modulo>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Divisibility> = _007::Type.new(:name<Q::Infix::Divisibility>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Concat> = _007::Type.new(:name<Q::Infix::Concat>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Replicate> = _007::Type.new(:name<Q::Infix::Replicate>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::ArrayReplicate> = _007::Type.new(:name<Q::Infix::ArrayReplicate>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Cons> = _007::Type.new(:name<Q::Infix::Cons>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Assignment> = _007::Type.new(:name<Q::Infix::Assignment>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Eq> = _007::Type.new(:name<Q::Infix::Eq>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Ne> = _007::Type.new(:name<Q::Infix::Ne>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Gt> = _007::Type.new(:name<Q::Infix::Gt>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Lt> = _007::Type.new(:name<Q::Infix::Lt>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Ge> = _007::Type.new(:name<Q::Infix::Ge>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Le> = _007::Type.new(:name<Q::Infix::Le>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Or> = _007::Type.new(:name<Q::Infix::Or>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::DefinedOr> = _007::Type.new(:name<Q::Infix::DefinedOr>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::And> = _007::Type.new(:name<Q::Infix::And>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::TypeMatch> = _007::Type.new(:name<Q::Infix::TypeMatch>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::TypeNonMatch> = _007::Type.new(:name<Q::Infix::TypeNonMatch>, :base(TYPE<Q::Infix>));
TYPE<Q::Postfix> = _007::Type.new(:name<Q::Postfix>, :base(TYPE<Q::Expr>), :fields["identifier", "operand"]);
TYPE<Q::Postfix::Index> = _007::Type.new(:name<Q::Postfix::Index>, :base(TYPE<Q::Postfix>), :fields["index"]);
TYPE<Q::Postfix::Call> = _007::Type.new(:name<Q::Postfix::Call>, :base(TYPE<Q::Postfix>), :fields["argumentlist"]);
TYPE<Q::Postfix::Property> = _007::Type.new(:name<Q::Postfix::Property>, :base(TYPE<Q::Postfix>), :fields["property"]);
TYPE<Q::Unquote> = _007::Type.new(:name<Q::Unquote>, :base(TYPE<Q>), :fields["qtype", "expr"]);
TYPE<Q::Unquote::Prefix> = _007::Type.new(:name<Q::Unquote::Prefix>, :base(TYPE<Q::Unquote>), :fields["operand"]);
TYPE<Q::Unquote::Infix> = _007::Type.new(:name<Q::Unquote::Infix>, :base(TYPE<Q::Unquote>), :fields["lhs", "rhs"]);
TYPE<Q::Statement> = _007::Type.new(:name<Q::Statement>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Statement::My> = _007::Type.new(:name<Q::Statement::My>, :base(TYPE<Q::Statement>), :fields["identifier", "expr"]);
TYPE<Q::Statement::Constant> = _007::Type.new(:name<Q::Statement::Constant>, :base(TYPE<Q::Statement>), :fields["identifier", "expr"]);
TYPE<Q::Statement::Block> = _007::Type.new(:name<Q::Statement::Block>, :base(TYPE<Q::Statement>), :fields["block"]);
TYPE<Q::Statement::Throw> = _007::Type.new(:name<Q::Statement::Throw>, :base(TYPE<Q::Statement>), :fields["expr"]);
TYPE<Q::Statement::Sub> = _007::Type.new(:name<Q::Statement::Sub>, :base(TYPE<Q::Statement>), :fields["identifier", "traitlist", "block"]);
TYPE<Q::Statement::Macro> = _007::Type.new(:name<Q::Statement::Macro>, :base(TYPE<Q::Statement>), :fields["identifier", "traitlist", "block"]);
TYPE<Q::Statement::BEGIN> = _007::Type.new(:name<Q::Statement::BEGIN>, :base(TYPE<Q::Statement>), :fields["block"]);
TYPE<Q::Statement::Class> = _007::Type.new(:name<Q::Statement::Class>, :base(TYPE<Q::Statement>), :fields["block"]);
TYPE<Q::CompUnit> = _007::Type.new(:name<Q::CompUnit>, :base(TYPE<Q::Statement::Block>));
TYPE<Q::Statement::Return> = _007::Type.new(:name<Q::Statement::Return>, :base(TYPE<Q::Statement>), :fields["expr"]);
TYPE<Q::Statement::Expr> = _007::Type.new(:name<Q::Statement::Expr>, :base(TYPE<Q::Statement>), :fields["expr"]);
TYPE<Q::Statement::If> = _007::Type.new(:name<Q::Statement::If>, :base(TYPE<Q::Statement>), :fields["expr", "block", "else"]);
TYPE<Q::Statement::For> = _007::Type.new(:name<Q::Statement::For>, :base(TYPE<Q::Statement>), :fields["expr", "block"]);
TYPE<Q::Statement::While> = _007::Type.new(:name<Q::Statement::While>, :base(TYPE<Q::Statement>), :fields["expr", "block"]);
TYPE<Q::StatementList> = _007::Type.new(:name<Q::StatementList>, :base(TYPE<Q>), :fields["statements"]);
TYPE<Q::ArgumentList> = _007::Type.new(:name<Q::ArgumentList>, :base(TYPE<Q>), :fields["arguments"]);
TYPE<Q::Parameter> = _007::Type.new(:name<Q::Parameter>, :base(TYPE<Q>), :fields["identifier"]);
TYPE<Q::ParameterList> = _007::Type.new(:name<Q::ParameterList>, :base(TYPE<Q>), :fields["parameters"]);
TYPE<Q::Property> = _007::Type.new(:name<Q::Property>, :base(TYPE<Q>), :fields["key", "value"]);
TYPE<Q::PropertyList> = _007::Type.new(:name<Q::PropertyList>, :base(TYPE<Q>), :fields["properties"]);
TYPE<Q::Trait> = _007::Type.new(:name<Q::Trait>, :base(TYPE<Q>), :fields["identifier", "expr"]);
TYPE<Q::TraitList> = _007::Type.new(:name<Q::TraitList>, :base(TYPE<Q>), :fields["traits"]);
TYPE<Q::Expr::StatementListAdapter> = _007::Type.new(:name<Q::Expr::StatementListAdapter>, :base(TYPE<Q::Expr>), :fields["statementlist"]);

class _007::Object {
    has $.type;
    has $.id = unique-id;
    has %.properties;

    multi method isa(Str $typename) {
        die "Asked to typecheck against $typename but no such type is declared"
            unless TYPE{$typename} :exists;

        return self.isa(TYPE{$typename});
    }

    multi method isa(_007::Type $type) {
        # We return `self` as an "interesting truthy value" so as to enable
        # renaming as part of finding out an object's true type:
        #
        #   if $ast.isa("Q::StatementList") -> $statementlist {
        #       # ...
        #   }

        return $type (elem) $.type.type-chain && self;
    }

    method attributes { () }

    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }

    method quoted-Str { self.Str }

    method truthy { truthy(self) }
}

class _007::Object::Enum is _007::Object {
}

class _007::Object::Wrapped is _007::Object {
    has $.value;

    method truthy { ?$.value }

    method quoted-Str {
        if $.type === TYPE<Str> {
            return q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["];
        }
        if $.type === TYPE<Array> {
            if %*stringification-seen{self.WHICH}++ {
                return "[...]";
            }
            return "[" ~ @($.value)».quoted-Str.join(', ') ~ "]";
        }
        if $.type === TYPE<Dict> {
            if %*stringification-seen{self.WHICH}++ {
                return "\{...\}";
            }
            return '{' ~ %.value.map({
                my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                    ?? .key
                    !! wrap(.key).quoted-Str;
                "{$key}: {.value.quoted-Str}"
            }).sort.join(', ') ~ '}';
        }
        return self.Str;
    }
}

constant NONE is export = _007::Object::Enum.new(:type(TYPE<NoneType>));

# Now we can install NONE into TYPE<Object>.base
TYPE<Object>.install-base(NONE);

constant TRUE is export = _007::Object::Enum.new(:type(TYPE<Bool>));
constant FALSE is export = _007::Object::Enum.new(:type(TYPE<Bool>));

# XXX: this is not optimal -- I wanted to declare these as part of the types themselves, but
# a rakudobug currently prevents subs in constants from being accessed from another module
sub bound-method($object, $name) is export {
    if $object.isa("Q::Statement::Block") && $name eq "run" {
        return sub run-q-statement-block($runtime) {
            $runtime.enter(
                $runtime.current-frame,
                $object.properties<block>.properties<static-lexpad>,
                $object.properties<block>.properties<statementlist>);
            bound-method($object.properties<block>.properties<statementlist>, "run")($runtime);
            $runtime.leave;
        };
    }

    if $object.isa("Q::StatementList") && $name eq "run" {
        return sub run-q-statementlist($runtime) {
            for $object.properties<statements>.value -> $statement {
                my $value = bound-method($statement, "run")($runtime);
                LAST if $statement.isa("Q::Statement::Expr") {
                    return $value;
                }
            }
        };
    }

    if $object.isa("Q::Statement::Expr") && $name eq "run" {
        return sub run-q-statement-expr($runtime) {
            return bound-method($object.properties<expr>, "eval")($runtime);
        };
    }

    if $object.isa("Q::Identifier") && $name eq "eval" {
        return sub eval-q-identifier($runtime) {
            return $runtime.get-var($object.properties<name>.value, $object.properties<frame>);
        };
    }

    if $object.isa("Q::Literal::Int") && $name eq "eval" {
        return sub eval-q-literal-int($runtime) {
            return $object.properties<value>;
        };
    }

    if $object.isa("Q::Literal::Str") && $name eq "eval" {
        return sub eval-q-literal-str($runtime) {
            return $object.properties<value>;
        };
    }

    if $object.isa("Q::Term::Dict") && $name eq "eval" {
        return sub eval-q-term-dict($runtime) {
            return wrap(hash($object.properties<propertylist>.properties<properties>.value.map({
                .properties<key>.value => bound-method(.properties<value>, "eval")($runtime);
            })));
        };
    }

    if $object.isa("Q::Identifier") && $name eq "put-value" {
        return sub put-value-q-identifier($value, $runtime) {
            $runtime.put-var($object, $value);
        };
    }

    if $object.isa("Q::Statement::Class") && $name eq "run" {
        return sub run-q-statement-class($runtime) {
            # a class block does not run at runtime
        };
    }

    if $object.isa("Q::Statement::Sub") && $name eq "run" {
        return sub run-q-statement-sub($runtime) {
            # a sub declaration does not run at runtime
        };
    }

    if $object.isa("Q::Statement::Macro") && $name eq "run" {
        return sub run-q-statement-macro($runtime) {
            # a macro declaration does not run at runtime
        };
    }

    if $object.isa("Q::Statement::For") && $name eq "run" {
        return sub run-q-statement-for($runtime) {
            my $count = $object.properties<block>.properties<parameterlist>.properties<parameters>.value.elems;
            die X::ParameterMismatch.new(
                :type("For loop"), :paramcount($count), :argcount("0 or 1"))
                if $count > 1;

            my $array = bound-method($object.properties<expr>, "eval")($runtime);
            die X::TypeCheck.new(:operation("for loop"), :got($array), :expected(_007::Object))
                unless $array ~~ _007::Object && $array.isa("Array");

            for $array.value -> $arg {
                $runtime.enter(
                    $runtime.current-frame,
                    $object.properties<block>.properties<static-lexpad>,
                    $object.properties<block>.properties<statementlist>);
                if $count == 1 {
                    $runtime.declare-var($object.properties<block>.properties<parameterlist>.properties<parameters>.value[0].properties<identifier>, $arg.list[0]);
                }
                bound-method($object.properties<block>.properties<statementlist>, "run")($runtime);
                $runtime.leave;
            }
        };
    }

    if $object.isa("Q::Statement::While") && $name eq "run" {
        return sub run-q-statement-while($runtime) {
            while (my $expr = bound-method($object.properties<expr>, "eval")($runtime)).truthy {
                my $paramcount = $object.properties<block>.properties<parameterlist>.properties<parameters>.value.elems;
                die X::ParameterMismatch.new(
                    :type("While loop"), :$paramcount, :argcount("0 or 1"))
                    if $paramcount > 1;
                $runtime.enter(
                    $runtime.current-frame,
                    $object.properties<block>.properties<static-lexpad>,
                    $object.properties<block>.properties<statementlist>);
                for @($object.properties<block>.properties<parameterlist>.properties<parameters>.value) Z $expr -> ($param, $arg) {
                    $runtime.declare-var($param.properties<identifier>, $arg);
                }
                bound-method($object.properties<block>.properties<statementlist>, "run")($runtime);
                $runtime.leave;
            }
        };
    }

    if $object.isa("Q::Term::Object") && $name eq "eval" {
        return sub eval-q-term-object($runtime) {
            my $type = $runtime.get-var(
                $object.properties<type>.properties<name>.value,
                $object.properties<type>.properties<frame>);
            if $type ~~ _007::Type {
                return $type.create(|hash($object.properties<propertylist>.properties<properties>.value.map({
                    .properties<key>.value => bound-method(.properties<value>, "eval")($runtime)
                })));
            }
            return $type.create($object.properties<propertylist>.properties<properties>.value.map({
                .properties<key>.value => bound-method(.properties<value>, "eval")($runtime)
            }));
        };
    }

    if $object.isa("Q::Infix::Assignment") && $name eq "eval" {
        return sub eval-q-infix-assignment($runtime) {
            my $value = bound-method($object.properties<rhs>, "eval")($runtime);
            bound-method($object.properties<lhs>, "put-value")($value, $runtime);
            return $value;
        };
    }

    if $object.isa("Q::Infix::And") && $name eq "eval" {
        return sub eval-q-infix-and($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            return $l.truthy
                ?? bound-method($object.properties<rhs>, "eval")($runtime)
                !! $l;
        };
    }

    if $object.isa("Q::Infix::Or") && $name eq "eval" {
        return sub eval-q-infix-or($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            return $l.truthy
                ?? $l
                !! bound-method($object.properties<rhs>, "eval")($runtime);
        };
    }

    if $object.isa("Q::Infix::DefinedOr") && $name eq "eval" {
        return sub eval-q-infix-definedor($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            return $l !=== NONE
                ?? $l
                !! bound-method($object.properties<rhs>, "eval")($runtime);
        };
    }

    # XXX: these should sit on Q::Infix
    my @infixes = <
        Q::Infix::TypeMatch
        Q::Infix::TypeNonMatch
        Q::Infix::Eq
        Q::Infix::Ne
        Q::Infix::Concat
        Q::Infix::Addition
        Q::Infix::Subtraction
        Q::Infix::Multiplication
        Q::Infix::Replicate
        Q::Infix::ArrayReplicate
        Q::Infix::Gt
        Q::Infix::Lt
        Q::Infix::Ge
        Q::Infix::Le
        Q::Infix::Modulo
        Q::Infix::Divisibility
        Q::Infix::Cons
        Q::Infix
    >;
    if any(@infixes.map({ $object.type === TYPE{$_} })) && $name eq "eval" {
        return sub eval-q-infix($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            my $r = bound-method($object.properties<rhs>, "eval")($runtime);
            my $c = bound-method($object.properties<identifier>, "eval")($runtime);
            return internal-call($c, $runtime, [$l, $r]);
        };
    }

    # XXX: these should sit on Q::Prefix
    my @prefixes = <
        Q::Prefix::Upto
        Q::Prefix::Str
        Q::Prefix::Plus
        Q::Prefix::Minus
        Q::Prefix::Not
        Q::Prefix
    >;
    if any(@prefixes.map({ $object.type === TYPE{$_} })) && $name eq "eval" {
        return sub eval-q-prefix($runtime) {
            my $e = bound-method($object.properties<operand>, "eval")($runtime);
            my $c = bound-method($object.properties<identifier>, "eval")($runtime);
            return internal-call($c, $runtime, [$e]);
        };
    }

    if $object.isa("Q::Postfix::Property") && $name eq "eval" {
        return sub eval-q-postfix-property($runtime) {
            my $obj = bound-method($object.properties<operand>, "eval")($runtime);
            my $propname = $object.properties<property>.properties<name>.value;
            $runtime.property($obj, $propname);
        };
    }

    if $object.isa("Q::Postfix::Index") && $name eq "eval" {
        return sub eval-q-postfix-index($runtime) {
            given bound-method($object.properties<operand>, "eval")($runtime) {
                if $_ ~~ _007::Object && .isa("Array") {
                    my $index = bound-method($object.properties<index>, "eval")($runtime);
                    die X::Subscript::NonInteger.new
                        unless $index ~~ _007::Object && $index.isa("Int");
                    die X::Subscript::TooLarge.new(:value($index.value), :length(+.value))
                        if $index.value >= .value;
                    die X::Subscript::Negative.new(:$index, :type([]))
                        if $index.value < 0;
                    return .value[$index.value];
                }
                if $_ ~~ _007::Object && (.isa("Dict") || .isa("Sub") || .isa("Q")) {
                    my $property = bound-method($object.properties<index>, "eval")($runtime);
                    die X::Subscript::NonString.new
                        unless $property ~~ _007::Object && $property.isa("Str");
                    my $propname = $property.value;
                    return $runtime.property($_, $propname);
                }
                die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(_007::Object));
            }
        };
    }

    if $object.isa("Q::Postfix::Call") && $name eq "eval" {
        return sub eval-q-postfix-call($runtime) {
            my $c = bound-method($object.properties<operand>, "eval")($runtime);
            die "macro is called at runtime"
                if $c ~~ _007::Object && $c.isa("Macro");
            die "Trying to invoke a {$c.type.name}" # XXX: make this into an X::
                unless $c ~~ _007::Object && $c.isa("Sub");
            my @arguments = $object.properties<argumentlist>.properties<arguments>.value.map({
                bound-method($_, "eval")($runtime)
            });
            return internal-call($c, $runtime, @arguments);
        };
    }

    if $object.isa("Q::Postfix") && $name eq "eval" {
        return sub eval-q-postfix($runtime) {
            my $e = bound-method($object.properties<operand>, "eval")($runtime);
            my $c = bound-method($object.properties<identifier>, "eval")($runtime);
            return internal-call($c, $runtime, [$e]);
        };
    }

    if $object.isa("Q::Statement::My") && $name eq "run" {
        return sub run-q-statement-my($runtime) {
            return
                if $object.properties<expr> === NONE;

            my $value = bound-method($object.properties<expr>, "eval")($runtime);
            bound-method($object.properties<identifier>, "put-value")($value, $runtime);
        };
    }

    if $object.isa("Q::Statement::Constant") && $name eq "run" {
        return sub run-q-statement-constant($runtime) {
            # value has already been assigned
        };
    }

    if $object.isa("Q::Statement::If") && $name eq "run" {
        return sub run-q-statement-if($runtime) {
            my $expr = bound-method($object.properties<expr>, "eval")($runtime);
            if $expr.truthy {
                my $paramcount = $object.properties<block>.properties<parameterlist>.properties<parameters>.value.elems;
                die X::ParameterMismatch.new(:type("If statement"), :$paramcount, :argcount("0 or 1"))
                    if $paramcount > 1;
                $runtime.enter(
                    $runtime.current-frame,
                    $object.properties<block>.properties<static-lexpad>,
                    $object.properties<block>.properties<statementlist>);
                if $object.properties<block>.properties<parameterlist>.properties<parameters>.value == 1 {
                    $runtime.declare-var(
                        $object.properties<block>.properties<parameterlist>.properties<parameters>.value[0].properties<identifier>,
                        $expr);
                }
                bound-method($object.properties<block>.properties<statementlist>, "run")($runtime);
                $runtime.leave;
            }
            else {
                given $object.properties<else> {
                    when .isa("Q::Statement::If") {
                        bound-method($object.properties<else>, "run")($runtime)
                    }
                    when .isa("Q::Block") {
                        $runtime.enter(
                            $runtime.current-frame,
                            $object.properties<else>.properties<static-lexpad>,
                            $object.properties<else>.properties<statementlist>);
                        bound-method($object.properties<else>.properties<statementlist>, "run")($runtime);
                        $runtime.leave;
                    }
                }
            }
        };
    }

    if $object.isa("Q::Statement::Return") && $name eq "run" {
        return sub run-q-statement-return($runtime) {
            my $value = $object.properties<expr> === NONE
                ?? $object.properties<expr>
                !! bound-method($object.properties<expr>, "eval")($runtime);
            my $frame = $runtime.get-var("--RETURN-TO--");
            die X::Control::Return.new(:$value, :$frame);
        };
    }

    if $object.isa("Q::Term::Quasi") && $name eq "eval" {
        return sub eval-q-term-quasi($runtime) {
            sub interpolate($thing) {
                return wrap($thing.value.map(&interpolate))
                    if $thing ~~ _007::Object && $thing.isa("Array");

                sub interpolate-entry($_) { .key => interpolate(.value) }
                return wrap(hash($thing.value.map(&interpolate-entry)))
                    if $thing ~~ _007::Object && $thing.isa("Dict");

                return $thing
                    if $thing ~~ _007::Type;

                return $thing
                    if $thing ~~ _007::Object && ($thing.isa("Int") || $thing.isa("Str"));

                return $thing
                    if $thing ~~ _007::Object && $thing.isa("Sub");

                return $thing.type.create(:name($thing.properties<name>), :frame($runtime.current-frame))
                    if $thing ~~ _007::Object && $thing.isa("Q::Identifier");

                if $thing ~~ _007::Object && $thing.isa("Q::Unquote::Prefix") {
                    my $prefix = bound-method($thing.properties<expr>, "eval")($runtime);
                    die X::TypeCheck.new(:operation("interpolating an unquote"), :got($prefix), :expected(_007::Object))
                        unless $prefix ~~ _007::Object && $prefix.isa("Q::Prefix");
                    return $prefix.type.create(:identifier($prefix.properties<identifier>), :operand($thing.properties<operand>));
                }
                elsif $thing ~~ _007::Object && $thing.isa("Q::Unquote::Infix") {
                    my $infix = bound-method($thing.properties<expr>, "eval")($runtime);
                    die X::TypeCheck.new(:operation("interpolating an unquote"), :got($infix), :expected(_007::Object))
                        unless $infix ~~ _007::Object && $infix.isa("Q::Infix");
                    return $infix.type.create(:identifier($infix.properties<identifier>), :lhs($thing.properties<lhs>), :rhs($thing.properties<rhs>));
                }

                if $thing ~~ _007::Object && $thing.isa("Q::Unquote") {
                    my $ast = bound-method($thing.properties<expr>, "eval")($runtime);
                    die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
                        unless $ast ~~ _007::Object && $ast.isa("Q");
                    return $ast;
                }

                my %properties = $thing.properties.keys.map: -> $key { $key => interpolate($thing.properties{$key}) };

                $thing.type.create(|%properties);
            }

            if $object.properties<qtype>.value eq "Q::Unquote" && $object.properties<contents>.isa("Q::Unquote") {
                return $object.properties<contents>;
            }
            return interpolate($object.properties<contents>);
        };
    }

    if $object.isa("Q::Term::Sub") && $name eq "eval" {
        return sub eval-q-term-sub($runtime) {
            my $name = $object.properties<identifier> === NONE
                ?? wrap("")
                !! $object.properties<identifier>.properties<name>;
            my $parameterlist = $object.properties<block>.properties<parameterlist>;
            my $statementlist = $object.properties<block>.properties<statementlist>;
            my $static-lexpad = $object.properties<block>.properties<static-lexpad>;
            my $outer-frame = $runtime.current-frame;
            return TYPE<Sub>.create(:$name, :$parameterlist, :$statementlist, :$static-lexpad, :$outer-frame);
        };
    }

    if $object.isa("Q::Term::Array") && $name eq "eval" {
        return sub eval-q-term-array($runtime) {
            return wrap($object.properties<elements>.value.map({ bound-method($_, "eval")($runtime) }));
        };
    }

    if $object.isa("Q::Statement::Throw") && $name eq "run" {
        return sub eval-q-statement-throw($runtime) {
            my $value = $object.properties<expr> === NONE
                ?? TYPE<Exception>.create(:message(wrap("Died")))
                !! bound-method($object.properties<expr>, "eval")($runtime);
            die X::TypeCheck.new(:got($value), :expected(_007::Object))
                unless $value ~~ _007::Object && $value.isa("Exception");

            die X::_007::RuntimeException.new(:msg($value.properties<message>.value));
        };
    }

    if $object.isa("Q::Postfix::Index") && $name eq "put-value" {
        return sub put-value-q-postfix-index($value, $runtime) {
            given bound-method($object.properties<operand>, "eval")($runtime) {
                if $_ ~~ _007::Object && .isa("Array") {
                    my $index = bound-method($object.properties<index>, "eval")($runtime);
                    die X::Subscript::NonInteger.new
                        unless $index ~~ _007::Object && $index.isa("Int");
                    die X::Subscript::TooLarge.new(:value($index.value), :length(+.value))
                        if $index.value >= .value;
                    die X::Subscript::Negative.new(:$index, :type([]))
                        if $index.value < 0;
                    .value[$index.value] = $value;
                    return;
                }
                if $_ ~~ _007::Object && (.isa("Dict") || .isa("Q")) {
                    my $property = bound-method($object.properties<index>, "eval")($runtime);
                    die X::Subscript::NonString.new
                        unless $property ~~ _007::Object && $property.isa("Str");
                    my $propname = $property.value;
                    $runtime.put-property($_, $propname, $value);
                    return;
                }
                die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(_007::Object));
            }
        };
    }

    if $object.isa("Q::Postfix::Property") && $name eq "put-value" {
        return sub put-value-q-postfix-property($value, $runtime) {
            given bound-method($object.properties<operand>, "eval")($runtime) {
                if $_ ~~ _007::Object && (.isa("Dict") || .isa("Q")) {
                    my $propname = $object.properties<property>.properties<name>.value;
                    $runtime.put-property($_, $propname, $value);
                    return;
                }
                die "We don't handle this case yet"; # XXX: think more about this case
            }
        };
    }

    if $object.isa("Q::Statement::BEGIN") && $name eq "run" {
        return sub run-q-statement-begin($runtime) {
            # a BEGIN block does not run at runtime
        };
    }

    if $object.isa("Q::Term::Regex") && $name eq "eval" {
        return sub eval-q-term-regex($runtime) {
            TYPE<Regex>.create(:contents($object.properties<contents>));
        };
    }

    if $object.isa("Q::Literal::None") && $name eq "eval" {
        return sub eval-q-literal-none($runtime) {
            NONE;
        };
    }

    if $object.isa("Q::Literal::Bool") && $name eq "eval" {
        return sub eval-q-literal-bool($runtime) {
            $object.properties<value>;
        };
    }

    if $object.isa("Q::Expr::StatementListAdapter") && $name eq "eval" {
        return sub eval-q-expr-statementlistadapter($runtime) {
            return bound-method($object.properties<statementlist>, "run")($runtime);
        };
    }

    die "The invocant is undefined"
        if $object === Any;
    die "Method '$name' does not exist on {$object.type.Str}";
}

sub truthy($v) {
    $v !=== NONE && $v !=== FALSE
}

sub wrap($value) is export {
    if $value ~~ Bool {
        return $value ?? TRUE !! FALSE;
    }
    elsif $value ~~ Int {
        return _007::Object::Wrapped.new(:type(TYPE<Int>), :$value);
    }
    elsif $value ~~ Str {
        return _007::Object::Wrapped.new(:type(TYPE<Str>), :$value);
    }
    elsif $value ~~ Array | Seq {
        return _007::Object::Wrapped.new(:type(TYPE<Array>), :value($value.Array));
    }
    elsif $value ~~ Hash {
        return _007::Object::Wrapped.new(:type(TYPE<Dict>), :$value);
    }
    elsif $value ~~ Nil {
        return NONE;
    }
    else {
        die "Tried to wrap unknown value ", $value.^name;
    }
}

sub wrap-fn(&value, Str $name, $parameterlist, $statementlist) is export {
    my %properties =
        name => wrap($name),
        :$parameterlist,
        :$statementlist,
    ;
    return _007::Object::Wrapped.new(:type(TYPE<Sub>), :&value, :%properties);
}

sub internal-call(_007::Object $sub, $runtime, @arguments) is export {
    die "Tried to call a {$sub.^name}, expected a Sub"
        unless $sub ~~ _007::Object && $sub.type === TYPE<Sub> | TYPE<Macro>;   # XXX: should do subtyping check

    if $sub ~~ _007::Object::Wrapped && $sub.type === TYPE<Macro> {
        die "Don't handle the wrapped macro case yet";
    }

    if $sub ~~ _007::Object::Wrapped && $sub.type === TYPE<Sub> {
        return $sub.value()(|@arguments);
    }

    my $paramcount = $sub.properties<parameterlist>.properties<parameters>.value.elems;
    my $argcount = @arguments.elems;
    die X::ParameterMismatch.new(:type<Sub>, :$paramcount, :$argcount)
        unless $paramcount == $argcount;
    $runtime.enter($sub.properties<outer-frame>, $sub.properties<static-lexpad>, $sub.properties<statementlist>, $sub);
    for @($sub.properties<parameterlist>.properties<parameters>.value) Z @arguments -> ($param, $arg) {
        $runtime.declare-var($param.properties<identifier>, $arg);
    }
    $runtime.register-subhandler;
    my $frame = $runtime.current-frame;
    my $value = bound-method($sub.properties<statementlist>, "run")($runtime);
    $runtime.leave;
    CATCH {
        when X::Control::Return {
            $runtime.unroll-to($frame);
            $runtime.leave;
            return .value;
        }
    }
    return $value || NONE;
}

class Helper {
    sub escaped($name) {
        sub escape-backslashes($s) { $s.subst(/\\/, "\\\\", :g) }
        sub escape-less-thans($s) { $s.subst(/"<"/, "\\<", :g) }

        return $name
            unless $name ~~ /^ (prefix | infix | postfix) ':' (.+) /;

        return "{$0}:<{escape-less-thans escape-backslashes $1}>"
            if $1.contains(">") && $1.contains("»");

        return "{$0}:«{escape-backslashes $1}»"
            if $1.contains(">");

        return "{$0}:<{escape-backslashes $1}>";
    }

    sub pretty($parameterlist) {
        return sprintf "(%s)", $parameterlist.properties<parameters>.value.map({
            .properties<identifier>.properties<name>
        }).join(", ");
    }

    method Str { "<sub {$.escaped-name}{$.pretty-parameters}>" }

    our sub Str($_) {
        when _007::Type { "<type {.name}>" }
        when _007::Object {
            when NONE { "None" }
            when .type === TYPE<Bool> { $_ === TRUE ?? "True" !! "False" }
            when .type === TYPE<Array> { .quoted-Str }
            when .type === TYPE<Dict> { .quoted-Str }
            when .type === TYPE<Exception> { "Exception \{message: {.properties<message>.quoted-Str}\}" }
            when .type === TYPE<Sub> {
                sprintf "<sub %s%s>", escaped(.properties<name>.value), pretty(.properties<parameterlist>)
            }
            when .type === TYPE<Macro> {
                sprintf "<macro %s%s>", escaped(.properties<name>.value), pretty(.properties<parameterlist>)
            }
            when .type === TYPE<Regex> {
                "/" ~ .contents.quoted-Str ~ "/"
            }
            when .isa("Q") {
                my $self = $_;
                my @props = $self.type.type-chain.reverse.map({ .fields }).flat;
                # XXX: thuggish way to hide things that weren't listed in `attributes` before
                @props.=grep: {
                    !($self.isa("Q::Identifier") && $_ eq "frame") &&
                    !($self.isa("Q::Block") && $_ eq "static-lexpad")
                };
                if @props == 1 {
                    return "{$self.type.name} { ($self.properties{@props[0]} // NONE).quoted-Str }";
                }
                sub keyvalue($prop) { $prop ~ ": " ~ $self.properties{$prop}.quoted-Str }
                my $contents = @props.map(&keyvalue).join(",\n").indent(4);
                return "{$self.type.name} \{\n$contents\n\}";
            }
            when _007::Object::Wrapped { .value.Str }
            default { die "Unexpected type ", .^name }
        }
        default {
            my $self = $_;
            die "Unexpected type -- some invariant must be broken ({$self.^name})"
                unless $self.^name ~~ /^ "Q::"/;    # type not introduced yet; can't typecheck

            sub aname($attr) { $attr.name.substr(2) }
            sub avalue($attr, $obj) { $attr.get_value($obj) }

            my @attrs = $self.attributes;
            if @attrs == 1 {
                return "{.^name} { avalue(@attrs[0], $self).quoted-Str }";
            }
            sub keyvalue($attr) { aname($attr) ~ ": " ~ avalue($attr, $self).quoted-Str }
            my $contents = @attrs.map(&keyvalue).join(",\n").indent(4);
            return "{$self.^name} \{\n$contents\n\}";
        }
    }
}
