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

class _007::Object {
    has $.type;
    has $.id = unique-id;
    has %.properties;

    multi method is-a(Str $typename) {
        die "Asked to typecheck against $typename but no such type is declared"
            unless TYPE{$typename} :exists;

        return self.is-a(TYPE{$typename});
    }

    multi method is-a(_007::Type $type) {
        # We return `self` as an "interesting truthy value" so as to enable
        # renaming as part of finding out an object's true type:
        #
        #   if $ast.is-a("Q::StatementList") -> $statementlist {
        #       # ...
        #   }

        return $type (elem) $.type.type-chain && self;
    }
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

    my $fields = set($type.type-chain.map({ .fields }));
    my $seen = set();
    for %properties.keys.sort -> $property {
        die X::Property::NotDeclared.new(:type($type.name), :$property)
            unless $property (elem) $fields;

        die X::Property::Duplicate.new(:type($type.name), :$property)
            if $property (elem) $seen;

        $seen (|)= $property;
    }
    # XXX: need to screen for required properties by traversing @.fields, but we don't have the
    #      infrastructure in terms of a way to mark up a field as required

    # XXX: for now, let's pretend all properties are required. not pleasant, but we can live with it for a short time
    for $fields.keys -> $field {
        die "Need to pass property '$field' when creating a {$type.name}"
            unless $field (elem) $seen;
    }

    # XXX: ditto for property default values

    return _007::Object.new(:$type, :%properties);
}

class _007::Object::Enum is _007::Object {
    has Str $.name;
}

class _007::Object::Wrapped is _007::Object {
    has $.value;
}

constant NONE is export = _007::Object::Enum.new(:type(TYPE<NoneType>), :name<None>);

# Now we can install NONE into TYPE<Object>.base
TYPE<Object>.install-base(NONE);

constant TRUE is export = _007::Object::Enum.new(:type(TYPE<Bool>), :name<True>);
constant FALSE is export = _007::Object::Enum.new(:type(TYPE<Bool>), :name<False>);

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

sub stringify($object) is export {
    my $s = bound-method($object, "Str")();
    die X::Type.new(:operation<stringification>, :got($s), :expected(TYPE<Str>))
        unless $s.is-a("Str");
    return $s.value;
}

sub reprify($object) is export {
    my $s = bound-method($object, "repr")();
    die X::Type.new(:operation<reprification>, :got($s), :expected(TYPE<Str>))
        unless $s.is-a("Str");
    return $s.value;
}

sub boolify($object) is export {
    my $s = bound-method($object, "Bool")();
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
sub bound-method($object, $name) is export {
    if $object.is-a("Q::Statement::Block") && $name eq "run" {
        return sub run-q-statement-block($runtime) {
            $runtime.enter(
                $runtime.current-frame,
                $object.properties<block>.properties<static-lexpad>,
                $object.properties<block>.properties<statementlist>);
            bound-method($object.properties<block>.properties<statementlist>, "run")($runtime);
            $runtime.leave;
        };
    }

    if $object.is-a("Q::StatementList") && $name eq "run" {
        return sub run-q-statementlist($runtime) {
            for $object.properties<statements>.value -> $statement {
                my $value = bound-method($statement, "run")($runtime);
                LAST if $statement.is-a("Q::Statement::Expr") {
                    return $value;
                }
            }
        };
    }

    if $object.is-a("Q::Statement::Expr") && $name eq "run" {
        return sub run-q-statement-expr($runtime) {
            return bound-method($object.properties<expr>, "eval")($runtime);
        };
    }

    if $object.is-a("Q::Identifier") && $name eq "eval" {
        return sub eval-q-identifier($runtime) {
            return $runtime.get-var($object.properties<name>.value, $object.properties<frame>);
        };
    }

    if $object.is-a("Q::Literal::Int") && $name eq "eval" {
        return sub eval-q-literal-int($runtime) {
            return $object.properties<value>;
        };
    }

    if $object.is-a("Q::Literal::Str") && $name eq "eval" {
        return sub eval-q-literal-str($runtime) {
            return $object.properties<value>;
        };
    }

    if $object.is-a("Q::Term::Dict") && $name eq "eval" {
        return sub eval-q-term-dict($runtime) {
            return wrap(hash($object.properties<propertylist>.properties<properties>.value.map({
                .properties<key>.value => bound-method(.properties<value>, "eval")($runtime);
            })));
        };
    }

    if $object.is-a("Q::Identifier") && $name eq "put-value" {
        return sub put-value-q-identifier($value, $runtime) {
            $runtime.put-var($object, $value);
        };
    }

    if $object.is-a("Q::Statement::Class") && $name eq "run" {
        return sub run-q-statement-class($runtime) {
            # a class block does not run at runtime
        };
    }

    if $object.is-a("Q::Statement::Sub") && $name eq "run" {
        return sub run-q-statement-sub($runtime) {
            # a sub declaration does not run at runtime
        };
    }

    if $object.is-a("Q::Statement::Macro") && $name eq "run" {
        return sub run-q-statement-macro($runtime) {
            # a macro declaration does not run at runtime
        };
    }

    if $object.is-a("Q::Statement::For") && $name eq "run" {
        return sub run-q-statement-for($runtime) {
            my $count = $object.properties<block>.properties<parameterlist>.properties<parameters>.value.elems;
            die X::ParameterMismatch.new(
                :type("For loop"), :paramcount($count), :argcount("0 or 1"))
                if $count > 1;

            my $array = bound-method($object.properties<expr>, "eval")($runtime);
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
                bound-method($object.properties<block>.properties<statementlist>, "run")($runtime);
                $runtime.leave;
            }
        };
    }

    if $object.is-a("Q::Statement::While") && $name eq "run" {
        return sub run-q-statement-while($runtime) {
            while boolify(my $expr = bound-method($object.properties<expr>, "eval")($runtime)) {
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

    if $object.is-a("Q::Term::Object") && $name eq "eval" {
        return sub eval-q-term-object($runtime) {
            my $type = $runtime.get-var(
                $object.properties<type>.properties<name>.value,
                $object.properties<type>.properties<frame>);
            if $type ~~ _007::Type {
                return create($type, |hash($object.properties<propertylist>.properties<properties>.value.map({
                    .properties<key>.value => bound-method(.properties<value>, "eval")($runtime)
                })));
            }
            return create($type, $object.properties<propertylist>.properties<properties>.value.map({
                .properties<key>.value => bound-method(.properties<value>, "eval")($runtime)
            }));
        };
    }

    if $object.is-a("Q::Infix::Assignment") && $name eq "eval" {
        return sub eval-q-infix-assignment($runtime) {
            my $value = bound-method($object.properties<rhs>, "eval")($runtime);
            bound-method($object.properties<lhs>, "put-value")($value, $runtime);
            return $value;
        };
    }

    if $object.is-a("Q::Infix::And") && $name eq "eval" {
        return sub eval-q-infix-and($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            return boolify($l)
                ?? bound-method($object.properties<rhs>, "eval")($runtime)
                !! $l;
        };
    }

    if $object.is-a("Q::Infix::Or") && $name eq "eval" {
        return sub eval-q-infix-or($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            return boolify($l)
                ?? $l
                !! bound-method($object.properties<rhs>, "eval")($runtime);
        };
    }

    if $object.is-a("Q::Infix::DefinedOr") && $name eq "eval" {
        return sub eval-q-infix-definedor($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            return $l !=== NONE
                ?? $l
                !! bound-method($object.properties<rhs>, "eval")($runtime);
        };
    }

    if $object.is-a("Q::Infix") && $name eq "eval" {
        return sub eval-q-infix($runtime) {
            my $l = bound-method($object.properties<lhs>, "eval")($runtime);
            my $r = bound-method($object.properties<rhs>, "eval")($runtime);
            my $c = bound-method($object.properties<identifier>, "eval")($runtime);
            return internal-call($c, $runtime, [$l, $r]);
        };
    }

    if $object.is-a("Q::Prefix") && $name eq "eval" {
        return sub eval-q-prefix($runtime) {
            my $e = bound-method($object.properties<operand>, "eval")($runtime);
            my $c = bound-method($object.properties<identifier>, "eval")($runtime);
            return internal-call($c, $runtime, [$e]);
        };
    }

    if $object.is-a("Q::Postfix::Property") && $name eq "eval" {
        return sub eval-q-postfix-property($runtime) {
            my $obj = bound-method($object.properties<operand>, "eval")($runtime);
            my $propname = $object.properties<property>.properties<name>.value;
            $runtime.property($obj, $propname);
        };
    }

    if $object.is-a("Q::Postfix::Index") && $name eq "eval" {
        return sub eval-q-postfix-index($runtime) {
            given bound-method($object.properties<operand>, "eval")($runtime) {
                if .is-a("Array") {
                    my $index = bound-method($object.properties<index>, "eval")($runtime);
                    die X::Subscript::NonInteger.new
                        unless $index.is-a("Int");
                    die X::Subscript::TooLarge.new(:value($index.value), :length(+.value))
                        if $index.value >= .value;
                    die X::Subscript::Negative.new(:$index, :type([]))
                        if $index.value < 0;
                    return .value[$index.value];
                }
                if .is-a("Dict") {
                    my $property = bound-method($object.properties<index>, "eval")($runtime);
                    die X::Subscript::NonString.new
                        unless $property.is-a("Str");
                    my $key = $property.value;
                    return .value{$key};
                }
                die X::Type.new(:operation<indexing>, :got($_), :expected(TYPE<Int>));
            }
        };
    }

    if $object.is-a("Q::Postfix::Call") && $name eq "eval" {
        return sub eval-q-postfix-call($runtime) {
            my $c = bound-method($object.properties<operand>, "eval")($runtime);
            die "macro is called at runtime"
                if $c.is-a("Macro");
            die "Trying to invoke a {$c.type.name}" # XXX: make this into an X::
                unless $c.is-a("Sub");
            my @arguments = $object.properties<argumentlist>.properties<arguments>.value.map({
                bound-method($_, "eval")($runtime)
            });
            return internal-call($c, $runtime, @arguments);
        };
    }

    if $object.is-a("Q::Postfix") && $name eq "eval" {
        return sub eval-q-postfix($runtime) {
            my $e = bound-method($object.properties<operand>, "eval")($runtime);
            my $c = bound-method($object.properties<identifier>, "eval")($runtime);
            return internal-call($c, $runtime, [$e]);
        };
    }

    if $object.is-a("Q::Statement::My") && $name eq "run" {
        return sub run-q-statement-my($runtime) {
            return
                if $object.properties<expr> === NONE;

            my $value = bound-method($object.properties<expr>, "eval")($runtime);
            bound-method($object.properties<identifier>, "put-value")($value, $runtime);
        };
    }

    if $object.is-a("Q::Statement::Constant") && $name eq "run" {
        return sub run-q-statement-constant($runtime) {
            # value has already been assigned
        };
    }

    if $object.is-a("Q::Statement::If") && $name eq "run" {
        return sub run-q-statement-if($runtime) {
            my $expr = bound-method($object.properties<expr>, "eval")($runtime);
            if boolify($expr) {
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
                    when .is-a("Q::Statement::If") {
                        bound-method($object.properties<else>, "run")($runtime)
                    }
                    when .is-a("Q::Block") {
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

    if $object.is-a("Q::Statement::Return") && $name eq "run" {
        return sub run-q-statement-return($runtime) {
            my $value = $object.properties<expr> === NONE
                ?? $object.properties<expr>
                !! bound-method($object.properties<expr>, "eval")($runtime);
            my $frame = $runtime.get-var("--RETURN-TO--");
            die X::Control::Return.new(:$value, :$frame);
        };
    }

    if $object.is-a("Q::Term::Quasi") && $name eq "eval" {
        return sub eval-q-term-quasi($runtime) {
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
                    my $prefix = bound-method($thing.properties<expr>, "eval")($runtime);
                    die X::Type.new(:operation("interpolating an unquote"), :got($prefix), :expected(TYPE<Q::Prefix>))
                        unless $prefix.is-a("Q::Prefix");
                    return create($prefix.type, :identifier($prefix.properties<identifier>), :operand($thing.properties<operand>));
                }
                elsif $thing.is-a("Q::Unquote::Infix") {
                    my $infix = bound-method($thing.properties<expr>, "eval")($runtime);
                    die X::Type.new(:operation("interpolating an unquote"), :got($infix), :expected(TYPE<Q::Infix>))
                        unless $infix.is-a("Q::Infix");
                    return create($infix.type, :identifier($infix.properties<identifier>), :lhs($thing.properties<lhs>), :rhs($thing.properties<rhs>));
                }

                if $thing.is-a("Q::Unquote") {
                    my $ast = bound-method($thing.properties<expr>, "eval")($runtime);
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
        return sub eval-q-term-sub($runtime) {
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
        return sub eval-q-term-array($runtime) {
            return wrap($object.properties<elements>.value.map({ bound-method($_, "eval")($runtime) }));
        };
    }

    if $object.is-a("Q::Statement::Throw") && $name eq "run" {
        return sub eval-q-statement-throw($runtime) {
            my $value = $object.properties<expr> === NONE
                ?? create(TYPE<Exception>, :message(wrap("Died")))
                !! bound-method($object.properties<expr>, "eval")($runtime);
            die X::Type.new(:got($value), :expected(TYPE<Exception>))
                unless $value.is-a("Exception");

            die X::_007::RuntimeException.new(:msg($value.properties<message>.value));
        };
    }

    if $object.is-a("Q::Postfix::Index") && $name eq "put-value" {
        return sub put-value-q-postfix-index($value, $runtime) {
            given bound-method($object.properties<operand>, "eval")($runtime) {
                if .is-a("Array") {
                    my $index = bound-method($object.properties<index>, "eval")($runtime);
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
                    my $property = bound-method($object.properties<index>, "eval")($runtime);
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
        return sub put-value-q-postfix-property($value, $runtime) {
            given bound-method($object.properties<operand>, "eval")($runtime) {
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
        return sub run-q-statement-begin($runtime) {
            # a BEGIN block does not run at runtime
        };
    }

    if $object.is-a("Q::Term::Regex") && $name eq "eval" {
        return sub eval-q-term-regex($runtime) {
            create(TYPE<Regex>, :contents($object.properties<contents>));
        };
    }

    if $object.is-a("Q::Literal::None") && $name eq "eval" {
        return sub eval-q-literal-none($runtime) {
            NONE;
        };
    }

    if $object.is-a("Q::Literal::Bool") && $name eq "eval" {
        return sub eval-q-literal-bool($runtime) {
            $object.properties<value>;
        };
    }

    if $object.is-a("Q::Expr::StatementListAdapter") && $name eq "eval" {
        return sub eval-q-expr-statementlistadapter($runtime) {
            return bound-method($object.properties<statementlist>, "run")($runtime);
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
            return wrap($object.name);
        }
    }

    if $object.is-a("NoneType") && $name eq "Str" {
        return sub str-nonetype() {
            return wrap($object.name);
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

            return wrap("[" ~ $object.value.map(&reprify).join(", ") ~ "]");
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
                    !! reprify(wrap(.key));
                "{$key}: {reprify(.value)}";
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
            return wrap(stringify($object));
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
            my @props = $object.type.type-chain.reverse.map({ .fields }).flat;
            # XXX: thuggish way to hide things that weren't listed in `attributes` before
            @props.=grep: {
                !($object.is-a("Q::Identifier") && $_ eq "frame") &&
                !($object.is-a("Q::Block") && $_ eq "static-lexpad")
            };
            if @props == 1 {
                return wrap("{$object.type.name} { reprify($object.properties{@props[0]}) }");
            }
            sub keyvalue($prop) { $prop ~ ": " ~ reprify($object.properties{$prop}) }
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

    die "The invocant is undefined"
        if $object === Any;
    die "Method '$name' does not exist on {$object.type.name}";
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
