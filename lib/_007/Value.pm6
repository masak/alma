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

sub make-type(Str $name, Bool :$backed) {
    my $base = TYPE<Object>;
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
    TYPE<Int> = make-type "Int", :backed;
    TYPE<None> = make-type "None";
    TYPE<Str> = make-type "Str", :backed;
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

sub make-int(Int $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Int>), :$native-value);
}

sub is-int($v) is export {
    $v ~~ _007::Value::Backed && is-instance($v, TYPE<Int>);
}

constant NONE is export = _007::Value.new(:type(TYPE<None>));

sub make-none() is export {
    NONE;
}

sub is-none($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<None>);
}

sub make-str(Str $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Str>), :$native-value);
}

sub is-str($v) is export {
    $v ~~ _007::Value::Backed && is-instance($v, TYPE<Str>);
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
    elsif $value ~~ _007::Value::Backed {
        return ~$value.native-value;
    }
    elsif $value.type === TYPE<Type> {
        return "<type {$value.slots<name>}>";
    }
    elsif $value.type === TYPE<Bool> {
        return $value === TRUE
            ?? "true"
            !! "false";
    }
    elsif $value.type === TYPE<None> {
        return "none";
    }
    elsif $value.type === TYPE<Object> {
        return "<object>";
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
    $value ~~ _007::Value::Backed
        ?? ?$value.native-value
        !! !is-none($value) && !is-bool($value) || $value === TRUE;
}
