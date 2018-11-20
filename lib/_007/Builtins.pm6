use _007::Val;
use _007::Q;
use _007::OpScope;
use _007::Equal;

class X::Control::Exit is Exception {
    has Int $.exit-code;
}

sub wrap($_) {
    when Val | Q { $_ }
    when Nil  { NONE }
    when Bool { Val::Bool.new(:value($_)) }
    when Int  { Val::Int.new(:value($_)) }
    when Str  { Val::Str.new(:value($_)) }
    when Array | Seq | List { Val::Array.new(:elements(.map(&wrap))) }
    default { die "Got some unknown value of type ", .^name }
}

subset ValOrQ of Any where Val | Q;

sub assert-type(:$value, ValOrQ:U :$type, Str :$operation) {
    die X::TypeCheck.new(:$operation, :got($value), :expected($type))
        unless $value ~~ $type;
}

sub assert-nonzero(:$value, :$operation, :$numerator) {
    die X::Numeric::DivideByZero.new(:using($operation), :$numerator)
        if $value == 0;
}

multi less-value($l, $) {
    assert-type(:value($l), :type(Val::Int), :operation<less>);
}
multi less-value(Val::Int $l, Val::Int $r) { $l.value < $r.value }
multi less-value(Val::Str $l, Val::Str $r) { $l.value lt $r.value }
multi more-value($l, $) {
    assert-type(:value($l), :type(Val::Int), :operation<more>);
}
multi more-value(Val::Int $l, Val::Int $r) { $l.value > $r.value }
multi more-value(Val::Str $l, Val::Str $r) { $l.value gt $r.value }

my role Placeholder {
    has $.qtype;
    has $.assoc;
    has %.precedence;
}
my class Placeholder::MacroOp does Placeholder {
}
sub macro-op(:$qtype, :$assoc?, :%precedence?) {
    Placeholder::MacroOp.new(:$qtype, :$assoc, :%precedence);
}

my class Placeholder::Op does Placeholder {
    has &.fn;
}
sub op(&fn, :$qtype, :$assoc?, :%precedence?) {
    Placeholder::Op.new(:&fn, :$qtype, :$assoc, :%precedence);
}

my @builtins =
    say => -> *$args {
        # implementation in Runtime.pm6
    },
    prompt => sub ($arg) {
        # implementation in Runtime.pm6
    },
    type => -> $arg { Val::Type.of($arg.WHAT) },
    exit => -> $int = Val::Int.new(:value(0)) {
        assert-type(:value($int), :type(Val::Int), :operation<exit>);
        my $exit-code = $int.value % 256;
        die X::Control::Exit.new(:$exit-code);
    },
    lvalue => Val::Macro.new-builtin(
        -> $expr {
            # implementation in Actions.pm6
        },
        "lvalue",
        Q::ParameterList.new(:parameters(Val::Array.new(:elements([
            Q::Parameter.new(:identifier(Q::Identifier.new(:name(Val::Str.new(:value<lvalue>)))))
        ])))),
        Q::StatementList.new()
    ),


    # OPERATORS (from loosest to tightest within each category)

    # assignment precedence
    'infix:=' => macro-op(
        :qtype(Q::Infix::Assignment),
        :assoc<right>,
    ),

    # disjunctive precedence
    'infix:||' => macro-op(
        :qtype(Q::Infix::Or),
    ),
    'infix://' => macro-op(
        :qtype(Q::Infix::DefinedOr),
        :precedence{ equiv => "infix:||" },
    ),

    # conjunctive precedence
    'infix:&&' => macro-op(
        :qtype(Q::Infix::And),
    ),

    # comparison precedence
    'infix:==' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return wrap(equal-value($lhs, $rhs));
        },
        :qtype(Q::Infix),
        :assoc<non>,
    ),
    'infix:!=' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return wrap(!equal-value($lhs, $rhs))
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:==" },
    ),
    'infix:<' => op(
        sub ($lhs, $rhs) {
            return wrap(less-value($lhs, $rhs))
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:==" },
    ),
    'infix:<=' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return wrap(less-value($lhs, $rhs) || equal-value($lhs, $rhs))
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:==" },
    ),
    'infix:>' => op(
        sub ($lhs, $rhs) {
            return wrap(more-value($lhs, $rhs) )
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:==" },
    ),
    'infix:>=' => op(
        sub ($lhs, $rhs) {
            my %*equality-seen;
            return wrap(more-value($lhs, $rhs) || equal-value($lhs, $rhs))
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:==" },
    ),
    'infix:~~' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($rhs), :type(Val::Type), :operation<~~>);

            return wrap($lhs ~~ $rhs.type);
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:==" },
    ),
    'infix:!~~' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($rhs), :type(Val::Type), :operation<!~~>);

            return wrap($lhs !~~ $rhs.type);
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:==" },
    ),

    # additive precedence
    'infix:+' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($lhs), :type(Val::Int), :operation<+>);
            assert-type(:value($rhs), :type(Val::Int), :operation<+>);

            return wrap($lhs.value + $rhs.value);
        },
        :qtype(Q::Infix),
    ),
    'infix:~' => op(
        sub ($lhs, $rhs) {
            return wrap($lhs.Str ~ $rhs.Str);
        },
        :qtype(Q::Infix),
        :precedence{ equiv => "infix:+" },
    ),
    'infix:-' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($lhs), :type(Val::Int), :operation<->);
            assert-type(:value($rhs), :type(Val::Int), :operation<->);

            return wrap($lhs.value - $rhs.value);
        },
        :qtype(Q::Infix),
    ),

    # multiplicative precedence
    'infix:*' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($lhs), :type(Val::Int), :operation<*>);
            assert-type(:value($rhs), :type(Val::Int), :operation<*>);

            return wrap($lhs.value * $rhs.value);
        },
        :qtype(Q::Infix),
    ),
    'infix:%' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($lhs), :type(Val::Int), :operation<%>);
            assert-type(:value($rhs), :type(Val::Int), :operation<%>);
            assert-nonzero(:value($rhs.value), :operation("infix:<%>"), :numerator($lhs.value));

            return wrap($lhs.value % $rhs.value);
        },
        :qtype(Q::Infix),
    ),
    'infix:%%' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($lhs), :type(Val::Int), :operation<%%>);
            assert-type(:value($rhs), :type(Val::Int), :operation<%%>);
            assert-nonzero(:value($rhs.value), :operation("infix:<%%>"), :numerator($lhs.value));

            return wrap($lhs.value %% $rhs.value);
        },
        :qtype(Q::Infix),
    ),
    'infix:divmod' => op(
        sub ($lhs, $rhs) {
            assert-type(:value($lhs), :type(Val::Int), :operation<divmod>);
            assert-type(:value($rhs), :type(Val::Int), :operation<divmod>);
            assert-nonzero(:value($rhs.value), :operation("infix:<divmod>"), :numerator($lhs.value));

            return Val::Tuple.new(:elements([
                wrap($lhs.value div $rhs.value),
                wrap($lhs.value % $rhs.value),
            ]));
        },
        :qtype(Q::Infix),
    ),

    # prefixes
    'prefix:~' => op(
        sub prefix-str($expr) {
            Val::Str.new(:value($expr.Str));
        },
        :qtype(Q::Prefix),
    ),
    'prefix:+' => op(
        sub prefix-plus($_) {
            when Val::Str {
                return wrap(.value.Int)
                    if .value ~~ /^ '-'? \d+ $/;
                proceed;
            }
            when Val::Int {
                return $_;
            }
            assert-type(:value($_), :type(Val::Int), :operation("prefix:<+>"));
        },
        :qtype(Q::Prefix),
    ),
    'prefix:-' => op(
        sub prefix-minus($_) {
            when Val::Str {
                return wrap(-.value.Int)
                    if .value ~~ /^ '-'? \d+ $/;
                proceed;
            }
            when Val::Int {
                return wrap(-.value);
            }
            assert-type(:value($_), :type(Val::Int), :operation("prefix:<->"));
        },
        :qtype(Q::Prefix),
    ),
    'prefix:?' => op(
        sub ($a) {
            return wrap(?$a.truthy)
        },
        :qtype(Q::Prefix),
    ),
    'prefix:!' => op(
        sub ($a) {
            return wrap(!$a.truthy)
        },
        :qtype(Q::Prefix),
    ),
    'prefix:^' => op(
        sub ($n) {
            assert-type(:value($n), :type(Val::Int), :operation("prefix:<^>"));

            return wrap([^$n.value]);
        },
        :qtype(Q::Prefix),
    ),

    # postfixes
    'postfix:[]' => macro-op(
        :qtype(Q::Postfix::Index),
    ),
    'postfix:()' => macro-op(
        :qtype(Q::Postfix::Call),
    ),
    'postfix:.' => macro-op(
        :qtype(Q::Postfix::Property),
    ),
;

for Val::.keys.map({ "Val::" ~ $_ }) -> $name {
    my $type = ::($name);
    push @builtins, ($type.^name.subst("Val::", "") => Val::Type.of($type));
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
my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(Val::Str.new(:$^value))))) };

@builtins.=map({
    when .value ~~ Val {
        .key => .value;
    }
    when .value ~~ Block {
        my @elements = .value.signature.params».name».&ditch-sigil».&parameter;
        if .key eq "say" {
            @elements = parameter("...args");
        }
        my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
        my $statementlist = Q::StatementList.new();
        .key => Val::Func.new-builtin(.value, .key, $parameterlist, $statementlist);
    }
    when .value ~~ Placeholder::MacroOp {
        my $name = .key;
        install-op($name, .value);
        my @elements = .value.qtype.attributes».name».substr(2).grep({ $_ ne "identifier" })».&parameter;
        my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
        my $statementlist = Q::StatementList.new();
        .key => Val::Func.new-builtin(sub () {}, $name, $parameterlist, $statementlist);
    }
    when .value ~~ Placeholder::Op {
        my $name = .key;
        install-op($name, .value);
        my &fn = .value.fn;
        my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
        my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
        my $statementlist = Q::StatementList.new();
        .key => Val::Func.new-builtin(&fn, $name, $parameterlist, $statementlist);
    }
    default { die "Unknown type {.value.^name}" }
});

my $builtins-pad = Val::Object.new;
for @builtins -> Pair (:key($name), :$value) {
    $builtins-pad.properties{$name} = $value;
}

sub builtins-pad() is export {
    return $builtins-pad;
}

sub opscope() is export {
    return $opscope;
}
