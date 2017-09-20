use _007::Type;

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

# We previously used Perl 6's X::TypeCheck, but it wants the .expected attribute to be a Perl 6 type.
# This is insufficient after switching to 007 having its own object system where basically everything is
# a _007::Object. Instead we use our own exception type, which is otherwise identical.
class X::Type is Exception {
    has $.operation;
    has $.got;
    has _007::Type $.expected;

    method message {
        "Type check failed in {$.operation}; expected {$.expected.name} but got {$.got.type.name} ({$.got.Str})"
    }
}

class X::Property::NotFound is Exception {
    has $.propname;
    has $.type;

    method message {
        "Property '$.propname' not found on object of type $.type"
    }
}

class X::Regex::InvalidMatchType is Exception {
    method message { "A regex can only match strings" }
}

class _007::Object does Typable {
    has $.id = unique-id;
    has %.properties;
}

sub create(_007::Type $type, *%properties) is export {
    die X::Uninstantiable.new(:name($type.name))
        if $type.is-abstract;

    # XXX: For Dict and Array, we might instead want to do a shallow copy
    if $type === TYPE<Dict> || $type === TYPE<Array> || $type === TYPE<Int> || $type === TYPE<Str> {
        return %properties<value>;
    }

    if $type === TYPE<Type> {
        return _007::Type.new(
            :name(%properties<name> ?? %properties<name>.value !! ""),
            :base(%properties<base> // TYPE<Object>),
            :fields(%properties<fields> ?? %properties<fields>.value !! []),
            :is-abstract(%properties<is-abstract> // False),
        );
    }

    my %fields = $type.type-chain.map({ .fields }).flat.map({ .<name> => $_ });
    my $seen = set();
    PROPERTY:
    for %properties.keys.sort -> $property {
        die X::Property::NotDeclared.new(:type($type.name), :$property)
            unless %fields{$property};

        die X::Property::Duplicate.new(:type($type.name), :$property)
            if $property (elem) $seen;

        $seen (|)= $property;

        my $value = %properties{$property};
        my $type-union = %fields{$property}<type>;
        for $type-union.split(/ \h* "|" \h* /) -> $fieldtypename {
            my $fieldtype = TYPE{$fieldtypename}
                or die "No such type {$fieldtypename}";
            next PROPERTY
                if $value.is-a($fieldtype);
        }
        die X::Type.new(
            :operation("instantiation of {$type.name} with property $property"),
            :got($value),
            :expected(_007::Type.new(:name($type-union))),
        );
    }
    # XXX: need to screen for required properties by traversing @.fields, but we don't have the
    #      infrastructure in terms of a way to mark up a field as required

    # XXX: for now, let's pretend all properties are required. not pleasant, but we can live with it for a short time
    for %fields.keys -> $field {
        die "Need to pass property '$field' when creating a {$type.name}"
            unless $field (elem) $seen;
    }

    # XXX: ditto for property default values

    return _007::Object.new(:$type, :%properties);
}

class _007::Object::Wrapped is _007::Object {
    has $.value;
}

constant NONE is export = create(TYPE<NoneType>, :name(_007::Object::Wrapped.new(:type(TYPE<Str>), :value("None"))));

# Now we can install NONE into TYPE<Object>.base
TYPE<Object>.install-base(NONE);

constant TRUE is export = create(TYPE<Bool>, :name(_007::Object::Wrapped.new(:type(TYPE<Str>), :value("True"))));
constant FALSE is export = create(TYPE<Bool>, :name(_007::Object::Wrapped.new(:type(TYPE<Str>), :value("False"))));

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
        .properties<identifier>.properties<name>.value
    }).join(", ");
}

sub stringify($object, $runtime) is export {
    my $s = bound-method($object, "Str", $runtime)();
    die X::Type.new(:operation<stringification>, :got($s), :expected(TYPE<Str>))
        unless $s.is-a("Str");
    return $s.value;
}

sub reprify($object, $runtime) is export {
    my $s = bound-method($object, "repr", $runtime)();
    die X::Type.new(:operation<reprification>, :got($s), :expected(TYPE<Str>))
        unless $s.is-a("Str");
    return $s.value;
}

sub boolify($object, $runtime) is export {
    my $s = bound-method($object, "Bool", $runtime)();
    die X::Type.new(:operation<boolification>, :got($s), :expected(TYPE<Bool>))
        unless $s.is-a("Bool");
    return $s === TRUE;
}

my $str-array-depth = 0;
my $str-array-seen;

my $str-dict-depth = 0;
my $str-dict-seen;

# XXX: now need the same thing done with objects

# XXX: this is not optimal -- I wanted to declare these as part of the types themselves, but
# a rakudobug currently prevents subs in constants from being accessed from another module
sub bound-method($object, $name, $runtime) is export {
    die "The invocant is undefined"
        if $object === Any;

    if $object.is-a("Q::Statement::Block") && $name eq "run" {
        return sub run-q-statement-block() {
            $runtime.enter(
                $runtime.current-frame,
                $object.properties<block>.properties<static-lexpad>,
                $object.properties<block>.properties<statementlist>);
            bound-method($object.properties<block>.properties<statementlist>, "run", $runtime)();
            $runtime.leave;
        };
    }

    if $object.is-a("Q::StatementList") && $name eq "run" {
        return sub run-q-statementlist() {
            for $object.properties<statements>.value -> $statement {
                my $value = bound-method($statement, "run", $runtime)();
                LAST if $statement.is-a("Q::Statement::Expr") {
                    return $value;
                }
            }
        };
    }

    if $object.is-a("Q::Statement::Expr") && $name eq "run" {
        return sub run-q-statement-expr() {
            return bound-method($object.properties<expr>, "eval", $runtime)();
        };
    }

    if $object.is-a("Q::Identifier") && $name eq "eval" {
        return sub eval-q-identifier() {
            return $runtime.get-var($object.properties<name>.value, $object.properties<frame>);
        };
    }

    if $object.is-a("Q::Literal::Int") && $name eq "eval" {
        return sub eval-q-literal-int() {
            return $object.properties<value>;
        };
    }

    if $object.is-a("Q::Literal::Str") && $name eq "eval" {
        return sub eval-q-literal-str() {
            return $object.properties<value>;
        };
    }

    if $object.is-a("Q::Term::Dict") && $name eq "eval" {
        return sub eval-q-term-dict() {
            return wrap(hash($object.properties<propertylist>.properties<properties>.value.map({
                .properties<key>.value => bound-method(.properties<value>, "eval", $runtime)();
            })));
        };
    }

    if $object.is-a("Q::Identifier") && $name eq "put-value" {
        return sub put-value-q-identifier($value) {
            $runtime.put-var($object, $value);
        };
    }

    if $object.is-a("Q::Statement::Class") && $name eq "run" {
        return sub run-q-statement-class() {
            # a class block does not run at runtime
        };
    }

    if $object.is-a("Q::Statement::Sub") && $name eq "run" {
        return sub run-q-statement-sub() {
            # a sub declaration does not run at runtime
        };
    }

    if $object.is-a("Q::Statement::Macro") && $name eq "run" {
        return sub run-q-statement-macro() {
            # a macro declaration does not run at runtime
        };
    }

    if $object.is-a("Q::Statement::For") && $name eq "run" {
        return sub run-q-statement-for() {
            my $count = $object.properties<block>.properties<parameterlist>.properties<parameters>.value.elems;
            die X::ParameterMismatch.new(
                :type("For loop"), :paramcount($count), :argcount("0 or 1"))
                if $count > 1;

            my $array = bound-method($object.properties<expr>, "eval", $runtime)();
            die X::Type.new(:operation("for loop"), :got($array), :expected(TYPE<Array>))
                unless $array.is-a("Array");

            for $array.value -> $arg {
                $runtime.enter(
                    $runtime.current-frame,
                    $object.properties<block>.properties<static-lexpad>,
                    $object.properties<block>.properties<statementlist>);
                if $count == 1 {
                    $runtime.declare-var($object.properties<block>.properties<parameterlist>.properties<parameters>.value[0].properties<identifier>, $arg.list[0]);
                }
                bound-method($object.properties<block>.properties<statementlist>, "run", $runtime)();
                $runtime.leave;
            }
        };
    }

    if $object.is-a("Q::Statement::While") && $name eq "run" {
        return sub run-q-statement-while() {
            while boolify(my $expr = bound-method($object.properties<expr>, "eval", $runtime)(), $runtime) {
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
                bound-method($object.properties<block>.properties<statementlist>, "run", $runtime)();
                $runtime.leave;
            }
        };
    }

    if $object.is-a("Q::Term::Object") && $name eq "eval" {
        return sub eval-q-term-object() {
            my $type = $runtime.get-var(
                $object.properties<type>.properties<name>.value,
                $object.properties<type>.properties<frame>);
            if $type ~~ _007::Type {
                return create($type, |hash($object.properties<propertylist>.properties<properties>.value.map({
                    .properties<key>.value => bound-method(.properties<value>, "eval", $runtime)()
                })));
            }
            return create($type, $object.properties<propertylist>.properties<properties>.value.map({
                .properties<key>.value => bound-method(.properties<value>, "eval", $runtime)()
            }));
        };
    }

    if $object.is-a("Q::Infix::Assignment") && $name eq "eval" {
        return sub eval-q-infix-assignment() {
            my $value = bound-method($object.properties<rhs>, "eval", $runtime)();
            bound-method($object.properties<lhs>, "put-value", $runtime)($value);
            return $value;
        };
    }

    if $object.is-a("Q::Infix::And") && $name eq "eval" {
        return sub eval-q-infix-and() {
            my $l = bound-method($object.properties<lhs>, "eval", $runtime)();
            return boolify($l, $runtime)
                ?? bound-method($object.properties<rhs>, "eval", $runtime)()
                !! $l;
        };
    }

    if $object.is-a("Q::Infix::Or") && $name eq "eval" {
        return sub eval-q-infix-or() {
            my $l = bound-method($object.properties<lhs>, "eval", $runtime)();
            return boolify($l, $runtime)
                ?? $l
                !! bound-method($object.properties<rhs>, "eval", $runtime)();
        };
    }

    if $object.is-a("Q::Infix::DefinedOr") && $name eq "eval" {
        return sub eval-q-infix-definedor() {
            my $l = bound-method($object.properties<lhs>, "eval", $runtime)();
            return $l !=== NONE
                ?? $l
                !! bound-method($object.properties<rhs>, "eval", $runtime)();
        };
    }

    if $object.is-a("Q::Infix") && $name eq "eval" {
        return sub eval-q-infix() {
            my $l = bound-method($object.properties<lhs>, "eval", $runtime)();
            my $r = bound-method($object.properties<rhs>, "eval", $runtime)();
            my $c = bound-method($object.properties<identifier>, "eval", $runtime)();
            return internal-call($c, $runtime, [$l, $r]);
        };
    }

    if $object.is-a("Q::Prefix") && $name eq "eval" {
        return sub eval-q-prefix() {
            my $e = bound-method($object.properties<operand>, "eval", $runtime)();
            my $c = bound-method($object.properties<identifier>, "eval", $runtime)();
            return internal-call($c, $runtime, [$e]);
        };
    }

    if $object.is-a("Q::Postfix::Property") && $name eq "eval" {
        return sub eval-q-postfix-property() {
            my $obj = bound-method($object.properties<operand>, "eval", $runtime)();
            my $propname = $object.properties<property>.properties<name>.value;
            my @props = $obj.type.type-chain.map({ .fields }).flat.map({ .<name> });
            if $propname (elem) @props {
                if $obj.is-a("Type") && $propname eq "name" {
                    return wrap($obj.name);
                }
                return $obj.properties{$propname};
            }
            else {
                # XXX: don't want to do it like this
                # think I want a BoundMethod type instead
                my &fn = bound-method($obj, $propname, $runtime);
                my $name = &fn.name;
                my &ditch-sigil = { $^str.substr(1) };
                my &parameter = {
                    create(TYPE<Q::Parameter>,
                        :identifier(create(TYPE<Q::Identifier>,
                            :name(wrap($^value))
                            :frame(NONE))
                        )
                    )
                };
                my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
                my $parameters = wrap(@elements);
                my $parameterlist = create(TYPE<Q::ParameterList>, :$parameters);
                my $statementlist = create(TYPE<Q::StatementList>, :statements(wrap([])));
                return wrap-fn(&fn, $name, $parameterlist, $statementlist);
            }
        };
    }

    if $object.is-a("Q::Postfix::Index") && $name eq "eval" {
        return sub eval-q-postfix-index() {
            given bound-method($object.properties<operand>, "eval", $runtime)() {
                if .is-a("Array") {
                    my $index = bound-method($object.properties<index>, "eval", $runtime)();
                    die X::Subscript::NonInteger.new
                        unless $index.is-a("Int");
                    die X::Subscript::TooLarge.new(:value($index.value), :length(+.value))
                        if $index.value >= .value;
                    die X::Subscript::Negative.new(:$index, :type([]))
                        if $index.value < 0;
                    return .value[$index.value];
                }
                if .is-a("Dict") -> $dict {
                    my $property = bound-method($object.properties<index>, "eval", $runtime)();
                    die X::Subscript::NonString.new
                        unless $property.is-a("Str");
                    my $propname = $property.value;
                    die X::Property::NotFound.new(:$propname, :type<Dict>)
                        unless $dict.value{$propname} :exists;
                    return $dict.value{$propname};
                }
                die X::Type.new(:operation<indexing>, :got($_), :expected(TYPE<Int>));
            }
        };
    }

    if $object.is-a("Q::Postfix::Call") && $name eq "eval" {
        return sub eval-q-postfix-call() {
            my $c = bound-method($object.properties<operand>, "eval", $runtime)();
            die "macro is called at runtime"
                if $c.is-a("Macro");
            die "Trying to invoke a {$c.type.name}" # XXX: make this into an X::
                unless $c.is-a("Sub");
            my @arguments = $object.properties<argumentlist>.properties<arguments>.value.map({
                bound-method($_, "eval", $runtime)()
            });
            return internal-call($c, $runtime, @arguments);
        };
    }

    if $object.is-a("Q::Postfix") && $name eq "eval" {
        return sub eval-q-postfix() {
            my $e = bound-method($object.properties<operand>, "eval", $runtime)();
            my $c = bound-method($object.properties<identifier>, "eval", $runtime)();
            return internal-call($c, $runtime, [$e]);
        };
    }

    if $object.is-a("Q::Statement::My") && $name eq "run" {
        return sub run-q-statement-my() {
            return
                if $object.properties<expr> === NONE;

            my $value = bound-method($object.properties<expr>, "eval", $runtime)();
            bound-method($object.properties<identifier>, "put-value", $runtime)($value);
        };
    }

    if $object.is-a("Q::Statement::Constant") && $name eq "run" {
        return sub run-q-statement-constant() {
            # value has already been assigned
        };
    }

    if $object.is-a("Q::Statement::If") && $name eq "run" {
        return sub run-q-statement-if() {
            my $expr = bound-method($object.properties<expr>, "eval", $runtime)();
            if boolify($expr, $runtime) {
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
                bound-method($object.properties<block>.properties<statementlist>, "run", $runtime)();
                $runtime.leave;
            }
            else {
                given $object.properties<else> {
                    when .is-a("Q::Statement::If") {
                        bound-method($object.properties<else>, "run", $runtime)()
                    }
                    when .is-a("Q::Block") {
                        $runtime.enter(
                            $runtime.current-frame,
                            $object.properties<else>.properties<static-lexpad>,
                            $object.properties<else>.properties<statementlist>);
                        bound-method($object.properties<else>.properties<statementlist>, "run", $runtime)();
                        $runtime.leave;
                    }
                }
            }
        };
    }

    if $object.is-a("Q::Statement::Return") && $name eq "run" {
        return sub run-q-statement-return() {
            my $value = $object.properties<expr> === NONE
                ?? $object.properties<expr>
                !! bound-method($object.properties<expr>, "eval", $runtime)();
            my $frame = $runtime.get-var("--RETURN-TO--");
            die X::Control::Return.new(:$value, :$frame);
        };
    }

    if $object.is-a("Q::Term::Quasi") && $name eq "eval" {
        return sub eval-q-term-quasi() {
            sub interpolate($thing) {
                return wrap($thing.value.map(&interpolate))
                    if $thing.is-a("Array");

                sub interpolate-entry($_) { .key => interpolate(.value) }
                return wrap(hash($thing.value.map(&interpolate-entry)))
                    if $thing.is-a("Dict");

                return $thing
                    if $thing ~~ _007::Type;

                return $thing
                    if $thing.is-a("Int") || $thing.is-a("Str");

                return $thing
                    if $thing.is-a("Sub");

                return create($thing.type, :name($thing.properties<name>), :frame($runtime.current-frame))
                    if $thing.is-a("Q::Identifier");

                if $thing.is-a("Q::Unquote::Prefix") {
                    my $prefix = bound-method($thing.properties<expr>, "eval", $runtime)();
                    die X::Type.new(:operation("interpolating an unquote"), :got($prefix), :expected(TYPE<Q::Prefix>))
                        unless $prefix.is-a("Q::Prefix");
                    return create($prefix.type, :identifier($prefix.properties<identifier>), :operand($thing.properties<operand>));
                }
                elsif $thing.is-a("Q::Unquote::Infix") {
                    my $infix = bound-method($thing.properties<expr>, "eval", $runtime)();
                    die X::Type.new(:operation("interpolating an unquote"), :got($infix), :expected(TYPE<Q::Infix>))
                        unless $infix.is-a("Q::Infix");
                    return create($infix.type, :identifier($infix.properties<identifier>), :lhs($thing.properties<lhs>), :rhs($thing.properties<rhs>));
                }

                if $thing.is-a("Q::Unquote") {
                    my $ast = bound-method($thing.properties<expr>, "eval", $runtime)();
                    die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
                        unless $ast.is-a("Q");
                    return $ast;
                }

                my %properties = $thing.properties.keys.map: -> $key { $key => interpolate($thing.properties{$key}) };

                create($thing.type, |%properties);
            }

            if $object.properties<qtype>.value eq "Q::Unquote" && $object.properties<contents>.is-a("Q::Unquote") {
                return $object.properties<contents>;
            }
            return interpolate($object.properties<contents>);
        };
    }

    if $object.is-a("Q::Term::Sub") && $name eq "eval" {
        return sub eval-q-term-sub() {
            my $name = $object.properties<identifier> === NONE
                ?? wrap("")
                !! $object.properties<identifier>.properties<name>;
            my $parameterlist = $object.properties<block>.properties<parameterlist>;
            my $statementlist = $object.properties<block>.properties<statementlist>;
            my $static-lexpad = $object.properties<block>.properties<static-lexpad>;
            my $outer-frame = $runtime.current-frame;
            return create(TYPE<Sub>, :$name, :$parameterlist, :$statementlist, :$static-lexpad, :$outer-frame);
        };
    }

    if $object.is-a("Q::Term::Array") && $name eq "eval" {
        return sub eval-q-term-array() {
            return wrap($object.properties<elements>.value.map({ bound-method($_, "eval", $runtime)() }));
        };
    }

    if $object.is-a("Q::Statement::Throw") && $name eq "run" {
        return sub eval-q-statement-throw() {
            my $value = $object.properties<expr> === NONE
                ?? create(TYPE<Exception>, :message(wrap("Died")))
                !! bound-method($object.properties<expr>, "eval", $runtime)();
            die X::Type.new(:got($value), :expected(TYPE<Exception>))
                unless $value.is-a("Exception");

            die X::_007::RuntimeException.new(:msg($value.properties<message>.value));
        };
    }

    if $object.is-a("Q::Postfix::Index") && $name eq "put-value" {
        return sub put-value-q-postfix-index($value) {
            given bound-method($object.properties<operand>, "eval", $runtime)() {
                if .is-a("Array") {
                    my $index = bound-method($object.properties<index>, "eval", $runtime)();
                    die X::Subscript::NonInteger.new
                        unless $index.is-a("Int");
                    die X::Subscript::TooLarge.new(:value($index.value), :length(+.value))
                        if $index.value >= .value;
                    die X::Subscript::Negative.new(:$index, :type([]))
                        if $index.value < 0;
                    .value[$index.value] = $value;
                    return;
                }
                if .is-a("Dict") || .is-a("Q") {
                    my $property = bound-method($object.properties<index>, "eval", $runtime)();
                    die X::Subscript::NonString.new
                        unless $property.is-a("Str");
                    my $propname = $property.value;
                    $runtime.put-property($_, $propname, $value);
                    return;
                }
                die X::Type.new(:operation<indexing>, :got($_), :expected(TYPE<Int>));
            }
        };
    }

    if $object.is-a("Q::Postfix::Property") && $name eq "put-value" {
        return sub put-value-q-postfix-property($value) {
            given bound-method($object.properties<operand>, "eval", $runtime)() {
                if .is-a("Dict") || .is-a("Q") {
                    my $propname = $object.properties<property>.properties<name>.value;
                    $runtime.put-property($_, $propname, $value);
                    return;
                }
                die "We don't handle this case yet"; # XXX: think more about this case
            }
        };
    }

    if $object.is-a("Q::Statement::BEGIN") && $name eq "run" {
        return sub run-q-statement-begin() {
            # a BEGIN block does not run at runtime
        };
    }

    if $object.is-a("Q::Term::Regex") && $name eq "eval" {
        return sub eval-q-term-regex() {
            create(TYPE<Regex>, :contents($object.properties<contents>));
        };
    }

    if $object.is-a("Q::Literal::None") && $name eq "eval" {
        return sub eval-q-literal-none() {
            NONE;
        };
    }

    if $object.is-a("Q::Literal::Bool") && $name eq "eval" {
        return sub eval-q-literal-bool() {
            $object.properties<value>;
        };
    }

    if $object.is-a("Q::Expr::StatementListAdapter") && $name eq "eval" {
        return sub eval-q-expr-statementlistadapter() {
            return bound-method($object.properties<statementlist>, "run", $runtime)();
        };
    }

    if $object.is-a("Str") && $name eq "Str" {
        return sub str-str() {
            return $object;
        }
    }

    if $object.is-a("Int") && $name eq "Str" {
        return sub str-int() {
            return wrap(~$object.value);
        }
    }

    if $object.is-a("Bool") && $name eq "Str" {
        return sub str-bool() {
            return $object.properties<name>;
        }
    }

    if $object.is-a("NoneType") && $name eq "Str" {
        return sub str-nonetype() {
            return $object.properties<name>;
        }
    }

    if $object.is-a("Type") && $name eq "Str" {
        return sub str-type() {
            return wrap("<type {$object.name}>");
        }
    }

    if $object.is-a("Array") && $name eq "Str" {
        return sub str-array() {
            if $str-array-depth++ == 0 {
                $str-array-seen = {};
            }
            LEAVE $str-array-depth--;

            if $str-array-seen{$object.id}++ {
                return wrap("[...]");
            }

            return wrap("[" ~ $object.value.map({ reprify($_, $runtime) }).join(", ") ~ "]");
        };
    }

    if $object.is-a("Dict") && $name eq "Str" {
        return sub str-dict() {
            if $str-dict-depth++ == 0 {
                $str-dict-seen = {};
            }
            LEAVE $str-dict-depth--;

            if $str-dict-seen{$object.id}++ {
                return wrap(q[{...}]);
            }

            return wrap('{' ~ $object.value.map({
                my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                    ?? .key
                    !! reprify(wrap(.key), $runtime);
                "{$key}: {reprify(.value, $runtime)}";
            }).sort.join(', ') ~ '}');
        };
    }

    if $object.is-a("Str") && $name eq "repr" {
        return sub repr-str() {
            return wrap(q["] ~ $object.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]);
        }
    }

    if $object.is-a("Object") && $name eq "repr" {
        return sub repr-object() {
            return wrap(stringify($object, $runtime));
        }
    }

    if $object.is-a("Macro") && $name eq "Str" {
        return sub str-sub() {
            return wrap(
                sprintf "<macro %s%s>",
                    escaped($object.properties<name>.value),
                    pretty($object.properties<parameterlist>)
            );
        };
    }

    if $object.is-a("Sub") && $name eq "Str" {
        return sub str-sub() {
            return wrap(
                sprintf "<sub %s%s>",
                    escaped($object.properties<name>.value),
                    pretty($object.properties<parameterlist>)
            );
        };
    }

    if $object.is-a("Q") && $name eq "Str" {
        return sub str-q() {
            my @props = $object.type.type-chain.reverse.map({ .fields }).flat.map({ .<name> });
            # XXX: thuggish way to hide things that weren't listed in `attributes` before
            @props.=grep: {
                !($object.is-a("Q::Identifier") && $_ eq "frame") &&
                !($object.is-a("Q::Block") && $_ eq "static-lexpad")
            };
            if @props == 1 {
                return wrap("{$object.type.name} { reprify($object.properties{@props[0]}, $runtime) }");
            }
            sub keyvalue($prop) { $prop ~ ": " ~ reprify($object.properties{$prop}, $runtime) }
            my $contents = @props.map(&keyvalue).join(",\n").indent(4);
            return wrap("{$object.type.name} \{\n$contents\n\}");
        };
    }

    if $object.is-a("Bool") && $name eq "Bool" {
        return sub bool-bool() {
            return $object;
        };
    }

    if $object.is-a("NoneType") && $name eq "Bool" {
        return sub bool-nonetype() {
            return FALSE;
        };
    }

    if $object.is-a("Int") && $name eq "Bool" {
        return sub bool-int() {
            return wrap($object.value != 0);
        };
    }

    if $object.is-a("Str") && $name eq "Bool" {
        return sub bool-str() {
            return wrap($object.value ne "");
        };
    }

    if $object.is-a("Array") && $name eq "Bool" {
        return sub bool-array() {
            return wrap($object.value.elems > 0);
        };
    }

    if $object.is-a("Dict") && $name eq "Bool" {
        return sub bool-dict() {
            return wrap($object.value.keys > 0);
        };
    }

    if $object.is-a("Object") && $name eq "Bool" {
        return sub bool-object() {
            return TRUE;
        };
    }

    if $object.is-a("Int") && $name eq "abs" {
        return sub abs-int() {
            return wrap($object.value.abs);
        };
    }

    if $object.is-a("Int") && $name eq "chr" {
        return sub chr-int() {
            return wrap($object.value.chr);
        };
    }

    if $object.is-a("Str") && $name eq "ord" {
        return sub ord-str() {
            return wrap($object.value.ord);
        };
    }

    if $object.is-a("Str") && $name eq "chars" {
        return sub chars-str() {
            return wrap($object.value.chars);
        };
    }

    if $object.is-a("Str") && $name eq "uc" {
        return sub uc-str() {
            return wrap($object.value.uc);
        };
    }

    if $object.is-a("Str") && $name eq "lc" {
        return sub lc-str() {
            return wrap($object.value.lc);
        };
    }

    if $object.is-a("Str") && $name eq "trim" {
        return sub trim-str() {
            return wrap($object.value.trim);
        };
    }

    if $object.is-a("Str") && $name eq "split" {
        return sub split-str($sep) {
            die X::Type.new(:operation<split>, :got($sep), :expected(TYPE<Str>))
                unless $sep.is-a("Str");
            return wrap($object.value.split($sep.value).map(&wrap));
        };
    }

    if $object.is-a("Array") && $name eq "join" {
        return sub join-array($sep) {
            die X::Type.new(:operation<join>, :got($sep), :expected(TYPE<Str>))
                unless $sep.is-a("Str");
            return wrap($object.value.map({ stringify($_, $runtime) }).join($sep.value));
        };
    }

    if $object.is-a("Str") && $name eq "index" {
        return sub index-str($substr) {
            die X::Type.new(:operation<index>, :got($substr), :expected(TYPE<Str>))
                unless $substr.is-a("Str");
            return wrap($object.value.index($substr.value) // -1);
        };
    }

    if $object.is-a("Str") && $name eq "substr" {
        return sub substr-str($pos, $chars) {
            # XXX: typecheck $pos and $chars
            return wrap($object.value.substr($pos.value, $chars.value));
        };
    }

    if $object.is-a("Str") && $name eq "prefix" {
        return sub prefix-str($pos) {
            # XXX: typecheck $pos
            return wrap($object.value.substr(0, $pos.value));
        };
    }

    if $object.is-a("Str") && $name eq "suffix" {
        return sub suffix-str($pos) {
            # XXX: typecheck $pos
            return wrap($object.value.substr($pos.value));
        };
    }

    if $object.is-a("Str") && $name eq "contains" {
        return sub contains-str($substr) {
            die X::Type.new(:operation<contains>, :got($substr), :expected(TYPE<Str>))
                unless $substr.is-a("Str");
            return wrap($object.value.contains($substr.value));
        };
    }

    if $object.is-a("Str") && $name eq "charat" {
        return sub charat-str($pos) {
            die X::Type.new(:operation<charat>, :got($pos), :expected(TYPE<Int>))
                unless $pos.is-a("Int");

            my $s = $object.value;

            die X::Subscript::TooLarge.new(:value($pos.value), :length($s.chars))
                if $pos.value >= $s.chars;

            return wrap($s.substr($pos.value, 1));
        };
    }

    if $object.is-a("Array") && $name eq "concat" {
        return sub concat-array($array) {
            die X::Type.new(:operation<concat>, :got($array), :expected(TYPE<Array>))
                unless $array.is-a("Array");
            return wrap([|$object.value, |$array.value]);
        };
    }

    if $object.is-a("Array") && $name eq "reverse" {
        return sub reverse-array() {
            return wrap($object.value.reverse);
        };
    }

    if $object.is-a("Array") && $name eq "sort" {
        return sub sort-array() {
            # XXX: this method needs to be seriously reconsidered once comparison methods can be defined on
            # custom objects
            # XXX: should also disallow sorting on heterogenous types
            return wrap($object.value.map({
                die "Cannot sort a {.type.name}"
                    if $_ !~~ _007::Object::Wrapped;
                .value;
            }).sort().map(&wrap));
        };
    }

    if $object.is-a("Array") && $name eq "shuffle" {
        return sub shuffle-array() {
            return wrap($object.value.pick(*));
        };
    }

    if $object.is-a("Array") && $name eq "size" {
        return sub size-array() {
            return wrap($object.value.elems);
        };
    }

    if $object.is-a("Array") && $name eq "push" {
        return sub push-array($newelem) {
            $object.value.push($newelem);
            return NONE;
        };
    }

    if $object.is-a("Array") && $name eq "pop" {
        return sub pop-array() {
            die X::Cannot::Empty.new(:action<pop>, :what("Array"))
                if $object.value.elems == 0;
            return $object.value.pop();
        };
    }

    if $object.is-a("Array") && $name eq "shift" {
        return sub shift-array() {
            die X::Cannot::Empty.new(:action<pop>, :what($object.^name))
                if $object.value.elems == 0;
            return $object.value.shift();
        };
    }

    if $object.is-a("Array") && $name eq "unshift" {
        return sub unshift-array($newelem) {
            $object.value.unshift($newelem);
            return NONE;
        };
    }

    if $object.is-a("Array") && $name eq "map" {
        return sub map-array($fn) {
            # XXX: Need to typecheck here if $fn is callable
            my @elements = $object.value.map({ internal-call($fn, $runtime, [$_]) });
            return wrap(@elements);
        };
    }

    if $object.is-a("Array") && $name eq "filter" {
        return sub filter-array($fn) {
            # XXX: Need to typecheck here if $fn is callable
            my @elements = $object.value.grep({ boolify(internal-call($fn, $runtime, [$_]), $runtime) });
            return wrap(@elements);
        };
    }

    if $object.is-a("Regex") && $name eq "fullmatch" {
        return sub fullmatch-regex($str) {
            die X::Regex::InvalidMatchType.new
                unless $str.is-a("Str");

            my $regex-string = $object.properties<contents>.value;

            return wrap($regex-string eq $str.value);
        };
    }

    if $object.is-a("Regex") && $name eq "search" {
        return sub search-regex($str) {
            die X::Regex::InvalidMatchType.new
                unless $str.is-a("Str");

            my $regex-string = $object.properties<contents>.value;

            return wrap($str.value.contains($regex-string));
        };
    }

    if $object.is-a("Dict") && $name eq "size" {
        return sub size-dict() {
            return wrap($object.value.elems);
        };
    }

    if $object.is-a("Q") && $name eq "detach" {
        sub interpolate($thing) {
            return wrap($thing.value.map(&interpolate))
                if $thing.is-a("Array");

            sub interpolate-entry($_) { .key => interpolate(.value) }
            return wrap(hash($thing.value.map(&interpolate-entry)))
                if $thing.is-a("Dict");

            return create($thing.type, :name($thing.properties<name>), :frame(NONE))
                if $thing.is-a("Q::Identifier");

            return $thing
                if $thing.is-a("Q::Unquote");

            my %properties = $thing.type.type-chain.reverse.map({ .fields }).flat.map: -> $field {
                my $fieldname = $field<name>;
                $fieldname => interpolate($thing.properties{$fieldname});
            };

            create($thing.type, |%properties);
        }

        return sub detach-q() {
            return interpolate($object);
        };
    }

    if $object.is-a("Type") && $name eq "create" {
        return sub create-type($properties) {
            # XXX: check that $properties is an array of [k, v] arrays
            create($object, |hash($properties.value.map(-> $p {
                my ($k, $v) = @($p.value);
                $k.value => $v;
            })));
        };
    }

    if $object.is-a("Object") && $name eq "get" {
        return sub get-object($propname) {
            # XXX: typecheck $propname as Str
            die X::Property::NotFound.new(:$propname, :type($object.type.name))
                unless $object.properties{$propname.value} :exists;
            return $object.properties{$propname.value};
        };
    }

    if $object.is-a("Dict") && $name eq "keys" {
        return sub keys-dict() {
            return wrap($object.value.keys.map(&wrap));
        };
    }

    die X::Property::NotFound.new(:propname($name), :type($object.type.name));
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
        unless $sub.is-a("Sub");   # XXX: should do subtyping check

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
    my $value = bound-method($sub.properties<statementlist>, "run", $runtime)();
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
