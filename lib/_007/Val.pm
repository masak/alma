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

class Helper { ... }
class _007::Object { ... }

sub unique-id { ++$ }

constant TYPE = hash();

class _007::Type {
    has Str $.name;
    has $.base = TYPE<Object>;
    has @.fields;
    # XXX: $.id

    method install-base($none) {
        $!base = $none;
    }

    method attributes { () }

    method quoted-Str { self.Str }
    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }

    method create(*%properties) {
        my $type = $.name;
        my $fields = set(@.fields);
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
TYPE<Macro> = _007::Type.new(:name<Macro>, :base(TYPE<Sub>), :fields["name", "parameterlist", "statementlist", "static-lexpad", "outer-frame"]);
TYPE<Regex> = _007::Type.new(:name<Regex>, :fields["contents"]);

class _007::Object {
    has $.type;
    has $.id = unique-id;
    has %.properties;

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

role Val {
    method truthy { True }
    method attributes { self.^attributes }
    method quoted-Str { self.Str }

    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }
}

### ### Type
###
### A type in 007's type system. All values have a type, which determines
### the value's "shape": what properties it can have, and which of these
### are required.
###
###     say(type(007));         # --> `<type Int>`
###     say(type("Bond"));      # --> `<type Str>`
###     say(type({}));          # --> `<type Dict>`
###     say(type(type({})));    # --> `<type Type>`
###
### 007 comes with a number of built-in types: `NoneType`, `Bool`, `Int`,
### `Str`, `Array`, `Object`, `Regex`, `Type`, `Block`, `Sub`, `Macro`,
### and `Exception`.
###
### There's also a whole hierarchy of Q types, which describe parts of
### program structure.
###
### Besides these built-in types, the programmer can also introduce new
### types by using the `class` statement:
###
###     class C {       # TODO: improve this example
###     }
###     say(type(new C {}));    # --> `<type C>`
###     say(type(C));           # --> `<type Type>`
###
### If you want to check whether a certain object is of a certain type,
### you can use the `infix:<~~>` operator:
###
###     say(42 ~~ Int);         # --> `True`
###     say(42 ~~ Str);         # --> `False`
###
### The `infix:<~~>` operator respects subtyping, so checking against a
### wider type also gives a `True` result:
###
###     my q = new Q::Literal::Int { value: 42 };
###     say(q ~~ Q::Literal::Int);  # --> `True`
###     say(q ~~ Q::Literal);       # --> `True`
###     say(q ~~ Q);                # --> `True`
###     say(q ~~ Int);              # --> `False`
###
### If you want *exact* type matching (which isn't a very OO thing to want),
### consider using infix:<==> on the respective type objects instead:
###
###     my q = new Q::Literal::Str { value: "Bond" };
###     say(type(q) == Q::Literal::Str);    # --> `True`
###     say(type(q) == Q::Literal);         # --> `False`
###
class Val::Type does Val {
    has $.type;

    method of($type) {
        self.bless(:$type);
    }

    sub is-role($type) {
        my role R {};
        return $type.HOW ~~ R.HOW.WHAT;
    }

    method create(@properties) {
        # XXX: there used to be a Val__Object case here
        if $.type ~~ _007::Object {
            return $.type.new(:value(@properties[0].value.value));
        }
        elsif $.type ~~ Val::Type {
            my $name = @properties[0].value;
            return $.type.new(:type(EVAL qq[class :: \{
                method attributes \{ () \}
                method ^name(\$) \{ "{$name}" \}
            \}]));
        }
        elsif is-role($.type) {
            die X::Uninstantiable.new(:$.name);
        }
        else {
            return $.type.new(|%(@properties));
        }
    }

    method name {
        $.type.^name.subst(/^ "Val::"/, "");
    }
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

    my $paramcount = $sub.properties<parameterlist>.parameters.value.elems;
    my $argcount = @arguments.elems;
    die X::ParameterMismatch.new(:type<Sub>, :$paramcount, :$argcount)
        unless $paramcount == $argcount;
    $runtime.enter($sub.properties<outer-frame>, $sub.properties<static-lexpad>, $sub.properties<statementlist>, $sub);
    for @($sub.properties<parameterlist>.parameters.value) Z @arguments -> ($param, $arg) {
        $runtime.declare-var($param.identifier, $arg);
    }
    $runtime.register-subhandler;
    my $frame = $runtime.current-frame;
    my $value = $sub.properties<statementlist>.run($runtime);
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
        return sprintf "(%s)", $parameterlist.parameters.value».identifier».name.join(", ");
    }

    method Str { "<sub {$.escaped-name}{$.pretty-parameters}>" }

    our sub Str($_) {
        when Val::Type { "<type {.name}>" }
        when _007::Type { "<type {.name}>" }
        when _007::Object {
            when .type === TYPE<NoneType> { "None" }
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
