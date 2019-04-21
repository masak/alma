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

    method truthy { True }
}

class _007::Value::Backed is _007::Value {
    has $.native-value;

    method Str { ~$.native-value }

    method quoted-Str { self.Str }

    method truthy { ?$.native-value }
}

constant TYPE is export = {};

sub make-type(Str $name, Bool :$backed) {
    _007::Value.new(:type(TYPE<Type>), slots => { :$name, :$backed });
}

BEGIN {
    TYPE<Type> = _007::Value.new(:type(__ITSELF__), slots => { name => "Type" });
    TYPE<Int> = make-type "Int", :backed;
}

sub make-int(Int $native-value) is export {
    _007::Value::Backed.new(:type(TYPE<Int>), :$native-value);
}

sub is-int($v) is export {
    # XXX: exact type should be subtype
    $v ~~ _007::Value::Backed && $v.type === TYPE<Int>;
}

sub is-type($v) is export {
    # XXX: exact type should be subtype
    $v ~~ _007::Value && $v.type === TYPE<Type>;
}

sub stringify(_007::Value $value) {
    if $value ~~ _007::Value::Backed {
        return ~$value.native-value;
    }

    if $value.type === TYPE<Type> {
        return "<type {$value.slots<name>}>";
    }
}
