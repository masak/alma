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

    method Str { stringify(self) }

    method quoted-Str { stringify(self) }

    method attributes { () }

    method truthy { truth-value(self) }
}

class _007::Value::Backed is _007::Value {
    has $.native-value;

    method Str { ~$.native-value }

    method quoted-Str {
        return stringify-quoted(self);
    }
}

constant TYPE is export = {};

sub make-type(Str $name, Bool :$backed) {
    _007::Value.new(:type(TYPE<Type>), slots => { :$name, :$backed });
}

BEGIN {
    TYPE<Type> = _007::Value.new(:type(__ITSELF__), slots => { name => "Type" });
    TYPE<Bool> = make-type "Bool";
    TYPE<Exception> = make-type "Exception";
    TYPE<Int> = make-type "Int", :backed;
    TYPE<None> = make-type "None";
    TYPE<Str> = make-type "Str", :backed;
}

sub is-type($v) is export {
    # XXX: exact type should be subtype
    $v ~~ _007::Value && $v.type === TYPE<Type>;
}

constant FALSE is export = _007::Value.new(:type(TYPE<Bool>));
constant TRUE is export = _007::Value.new(:type(TYPE<Bool>));

sub make-bool(Bool $value) is export {
    $value ?? TRUE !! FALSE;
}

sub is-bool($v) is export {
    $v ~~ _007::Value && $v.type === TYPE<Bool>;
}

sub make-exception(_007::Value $message where &is-str) is export {
    _007::Value.new(:type(TYPE<Exception>), slots => { :$message });
}

sub is-exception($v) is export {
    $v ~~ _007::Value && $v.type === TYPE<Exception>;
}

sub make-int(Int $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Int>), :$native-value);
}

sub is-int($v) is export {
    # XXX: exact type should be subtype
    $v ~~ _007::Value::Backed && $v.type === TYPE<Int>;
}

constant NONE is export = _007::Value.new(:type(TYPE<None>));

sub make-none() is export {
    NONE;
}

sub is-none($v) is export {
    $v ~~ _007::Value && $v.type === TYPE<None>;
}

sub make-str(Str $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Str>), :$native-value);
}

sub is-str($v) is export {
    # XXX: exact type should be subtype
    $v ~~ _007::Value::Backed && $v.type === TYPE<Str>;
}

sub stringify(_007::Value $value) {
    if $value ~~ _007::Value::Backed {
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
    else {
        die "Unknown _007::Value type sent to stringify: ", $value.type.slots<name>;
    }
}

sub stringify-quoted(_007::Value::Backed $value) {
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
