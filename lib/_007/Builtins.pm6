use _007::Val;
use _007::Value;
use _007::Q;
use _007::OpScope;
use _007::Equal;

class X::Control::Exit is Exception {
    has Int $.exit-code;
}

subset ValOrQ of Any where Val | Q;

sub assert-type(:$value, ValOrQ:U :$type, Str :$operation) {
    die X::TypeCheck.new(:$operation, :got($value), :expected($type))
        unless $value ~~ $type;
}

sub assert-new-type(:$value, :$type, Str :$operation) {
    my $type-obj = $type ~~ Str
        ?? (TYPE{$type} or die "Type not found: {$type}")
        !! is-type($type)
            ?? $type
            !! $type ~~ _007::Value
                ?? die X::TypeCheck.new(:$operation, :got($value.type), :expected($type))
                !! die X::TypeCheck.new(:$operation, :got($value), :expected($type));
    die X::TypeCheck.new(:$operation, :got($value), :expected($type-obj))
        unless $value ~~ _007::Value && is-instance($value, $type-obj);
}

sub assert-nonzero(:$value, :$operation, :$numerator) {
    die X::Numeric::DivideByZero.new(:using($operation), :$numerator)
        if $value == 0;
}

multi less-value($l, $) {
    assert-new-type(:value($l), :type<Int>, :operation<less>);
}
multi less-value(_007::Value::Backed $l, _007::Value::Backed $r) {
    is-int($l) && is-int($r) && $l.native-value < $r.native-value ||
        is-str($l) && is-str($r) && $l.native-value lt $r.native-value;
}

multi more-value($l, $) {
    assert-new-type(:value($l), :type<Int>, :operation<more>);
}
multi more-value(_007::Value::Backed $l, _007::Value::Backed $r) {
    is-int($l) && is-int($r) && $l.native-value > $r.native-value ||
        is-str($l) && is-str($r) && $l.native-value gt $r.native-value;
}

my role Placeholder {
    has $.qtype;
    has $.assoc;
    has %.precedence;
}
my class Placeholder::MacroOp does Placeholder {
}
sub macro-op(_007::Value :$qtype where &is-type, :$assoc?, :%precedence?) {
    Placeholder::MacroOp.new(:$qtype, :$assoc, :%precedence);
}

my class Placeholder::Op does Placeholder {
    has &.fn;
}
sub op(&fn, :$assoc?, :%precedence?) {
    Placeholder::Op.new(:&fn, :$assoc, :%precedence);
}

my @builtins =
    say => -> *$args {
        # implementation in Runtime.pm
    },
    prompt => sub ($arg) {
        # implementation in Runtime.pm
    },
    type => -> $arg {
        $arg ~~ _007::Value
            ?? $arg.type
            !! Val::Type.of($arg.WHAT);
    },
    exit => -> $int = make-int(0) {
        assert-new-type(:value($int), :type<Int>, :operation<exit>);
        my $exit-code = $int.native-value % 256;
        die X::Control::Exit.new(:$exit-code);
    },
    assertType => -> $value, $type {
        if $type ~~ _007::Value {
            assert-new-type(:value($type), :type<Type>, :operation("assertType (checking the Type parameter)"));
            assert-new-type(:$value, :type($type), :operation<assertType>);
        }
        else {
            assert-type(:value($type), :type(Val::Type), :operation("assertType (checking the Type parameter)"));
            assert-type(:$value, :type($type.type), :operation<assertType>);
        }
    },

    # OPERATORS (from loosest to tightest within each category)

    # assignment precedence
    'infix:=' => macro-op(
        :qtype(TYPE<Q.Infix.Assignment>),
        :assoc<right>,
    ),

    # disjunctive precedence
    'infix:||' => macro-op(
        :qtype(TYPE<Q.Infix.Or>),
    ),
    'infix://' => macro-op(
        :qtype(TYPE<Q.Infix.DefinedOr>),
        :precedence{ equiv => "infix:||" },
    ),

    # conjunctive precedence
    'infix:&&' => macro-op(
        :qtype(TYPE<Q.Infix.And>),
    ),

    # comparison precedence
    'infix:==' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return make-bool(equal-value($lhs, $rhs));
        },
        :assoc<non>,
    ),
    'infix:!=' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return make-bool(!equal-value($lhs, $rhs));
        },
        :precedence{ equiv => "infix:==" },
    ),
    'infix:<' => op(
        sub ($lhs, $rhs) {
            return make-bool(less-value($lhs, $rhs));
        },
        :precedence{ equiv => "infix:==" },
    ),
    'infix:<=' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return make-bool(less-value($lhs, $rhs) || equal-value($lhs, $rhs));
        },
        :precedence{ equiv => "infix:==" },
    ),
    'infix:>' => op(
        sub ($lhs, $rhs) {
            return make-bool(more-value($lhs, $rhs));
        },
        :precedence{ equiv => "infix:==" },
    ),
    'infix:>=' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return make-bool(more-value($lhs, $rhs) || equal-value($lhs, $rhs));
        },
        :precedence{ equiv => "infix:==" },
    ),
    'infix:~~' => op(
        sub ($lhs, $rhs) {
            if is-type($rhs) {
                # XXX: Once we drop Val::Type, we should turn the type test below into an assert.
                # XXX: Once everything is ported over to _007::Value, the test against _007::Value
                #      will be unnecessary.
                return make-bool($rhs === TYPE<Object> || $lhs ~~ _007::Value && $lhs.type === $rhs);
            }
            assert-type(:value($rhs), :type(Val::Type), :operation<~~>);

            return make-bool($lhs ~~ $rhs.type);
        },
        :precedence{ equiv => "infix:==" },
    ),
    'infix:!~~' => op(
        sub ($lhs, $rhs) {
            if is-type($rhs) {
                # XXX: Once we drop Val::Type, we should turn the type test below into an assert.
                # XXX: Once everything is ported over to _007::Value, the test against _007::Value
                #      will be unnecessary.
                return make-bool($rhs !=== TYPE<Object> && ($lhs !~~ _007::Value || $lhs.type !=== $rhs));
            }
            assert-type(:value($rhs), :type(Val::Type), :operation<!~~>);

            return make-bool($lhs !~~ $rhs.type);
        },
        :precedence{ equiv => "infix:==" },
    ),

    # concatenation precedence
    'infix:~' => op(
        sub ($lhs, $rhs) {
            return make-str($lhs.Str ~ $rhs.Str);
        },
    ),

    # additive precedence
    'infix:+' => op(
        sub ($lhs, $rhs) {
            assert-new-type(:value($lhs), :type<Int>, :operation<+>);
            assert-new-type(:value($rhs), :type<Int>, :operation<+>);

            return make-int($lhs.native-value + $rhs.native-value);
        },
    ),
    'infix:-' => op(
        sub ($lhs, $rhs) {
            assert-new-type(:value($lhs), :type<Int>, :operation<->);
            assert-new-type(:value($rhs), :type<Int>, :operation<->);

            return make-int($lhs.native-value - $rhs.native-value);
        },
    ),

    # multiplicative precedence
    'infix:*' => op(
        sub ($lhs, $rhs) {
            assert-new-type(:value($lhs), :type<Int>, :operation<*>);
            assert-new-type(:value($rhs), :type<Int>, :operation<*>);

            return make-int($lhs.native-value * $rhs.native-value);
        },
    ),
    'infix:div' => op(
        sub ($lhs, $rhs) {
            assert-new-type(:value($lhs), :type<Int>, :operation<div>);
            assert-new-type(:value($rhs), :type<Int>, :operation<div>);
            assert-nonzero(:value($rhs.native-value), :operation("infix:<div>"), :numerator($lhs.native-value));

            return make-int($lhs.native-value div $rhs.native-value);
        },
    ),
    'infix:divmod' => op(
        sub ($lhs, $rhs) {
            assert-new-type(:value($lhs), :type<Int>, :operation<divmod>);
            assert-new-type(:value($rhs), :type<Int>, :operation<divmod>);
            assert-nonzero(:value($rhs.native-value), :operation("infix:<divmod>"), :numerator($lhs.native-value));

            return make-array([
                make-int($lhs.native-value div $rhs.native-value),
                make-int($lhs.native-value % $rhs.native-value),
            ]);
        },
        :precedence{ equiv => "infix:div" },
    ),
    'infix:%' => op(
        sub ($lhs, $rhs) {
            assert-new-type(:value($lhs), :type<Int>, :operation<%>);
            assert-new-type(:value($rhs), :type<Int>, :operation<%>);
            assert-nonzero(:value($rhs.native-value), :operation("infix:<%>"), :numerator($lhs.native-value));

            return make-int($lhs.native-value % $rhs.native-value);
        },
        :precedence{ equiv => "infix:div" },
    ),
    'infix:%%' => op(
        sub ($lhs, $rhs) {
            assert-new-type(:value($lhs), :type<Int>, :operation<%%>);
            assert-new-type(:value($rhs), :type<Int>, :operation<%%>);
            assert-nonzero(:value($rhs.native-value), :operation("infix:<%%>"), :numerator($lhs.native-value));

            return make-bool($lhs.native-value %% $rhs.native-value);
        },
        :precedence{ equiv => "infix:div" },
    ),

    # prefixes
    'prefix:~' => op(
        sub prefix-str($expr) {
            make-str($expr.Str);
        },
    ),
    'prefix:+' => op(
        sub prefix-plus($_) {
            when is-str($_) {
                return make-int(.native-value.Int)
                    if .native-value ~~ /^ '-'? \d+ $/;
                proceed;
            }
            when is-int($_) {
                return make-int(.native-value);
            }
            assert-new-type(:value($_), :type<Int>, :operation("prefix:<+>"));
        },
    ),
    'prefix:-' => op(
        sub prefix-minus($_) {
            when is-str($_) {
                return make-int(-.native-value.Int)
                    if .native-value ~~ /^ '-'? \d+ $/;
                proceed;
            }
            when is-int($_) {
                return make-int(-.native-value);
            }
            assert-new-type(:value($_), :type<Int>, :operation("prefix:<->"));
        },
    ),
    'prefix:?' => op(
        sub ($a) {
            return make-bool(?$a.truthy);
        },
    ),
    'prefix:!' => op(
        sub ($a) {
            return make-bool(!$a.truthy);
        },
    ),
    'prefix:^' => op(
        sub ($n) {
            assert-new-type(:value($n), :type<Int>, :operation("prefix:<^>"));

            return make-array((^$n.native-value).map(&make-int).Array);
        },
    ),

    # postfixes
    'postfix:[]' => macro-op(
        :qtype(TYPE<Q.Postfix.Index>),
    ),
    'postfix:()' => macro-op(
        :qtype(TYPE<Q.Postfix.Call>),
    ),
    'postfix:.' => macro-op(
        :qtype(TYPE<Q.Postfix.Property>),
    ),
;

for Val::.keys.map({ "Val::" ~ $_ }) -> $name {
    my $type = ::($name);
    push @builtins, ($type.^name.subst("Val::", "") => Val::Type.of($type));
}
for <Array Bool Dict Exception Func Int Macro None Object Str> -> $name {
    push @builtins, $name => TYPE{$name};
}
push @builtins, "Q" => Val::Type.of(Q);

my $opscope = _007::OpScope.new();

sub install-op($name, $placeholder) {
    $name ~~ /^ (prefix | infix | postfix) ':' (.+) $/
        or die "This shouldn't be an op";
    my $type = ~$0;
    my $opname = ~$1;
    my $qtype = $placeholder.qtype;
    my $assoc = $placeholder.assoc;
    my %precedence = $placeholder.precedence;
    $opscope.install($type, $opname, $qtype, :$assoc, :%precedence);
}

my &ditch-sigil = { $^str.substr(1) };
my &parameter = { make-q-parameter(make-q-identifier(make-str($^value))) };

@builtins.=map({
    when .value ~~ Val::Type {
        .key => .value;
    }
    when is-type(.value) {
        .key => .value;
    }
    when .value ~~ Block {
        my @parameters = .key eq "say"
            ?? parameter("...args")
            !! .value.signature.params».name».&ditch-sigil».&parameter;
        .key => make-func(.value, .key, @parameters);
    }
    when .value ~~ Placeholder::MacroOp {
        my $name = .key;
        install-op($name, .value);
        my @parameters = .value.qtype.attributes».name».substr(2).grep({ $_ ne "identifier" })».&parameter;
        .key => make-func(sub () {}, $name, @parameters);
    }
    when .value ~~ Placeholder::Op {
        my $name = .key;
        install-op($name, .value);
        my &fn = .value.fn;
        my @parameters = &fn.signature.params».name».&ditch-sigil».&parameter;
        .key => make-func(&fn, $name, @parameters);
    }
    default { die "Unknown type {.value.^name} installed in builtins" }
});

my $builtins-pad = make-dict();
for @builtins -> Pair (:key($name), :$value) {
    set-dict-property($builtins-pad, $name, $value);
}

sub builtins-pad() is export {
    return $builtins-pad;
}

sub opscope() is export {
    return $opscope;
}

