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
    TYPE<Func> = make-type "Func", :backed;
    TYPE<Int> = make-type "Int", :backed;
    TYPE<Macro> = make-type "Macro", :backed;
    TYPE<None> = make-type "None";
    TYPE<Regex> = make-type "Regex";
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

multi make-func(
    _007::Value $name where &is-str,
    $parameterlist where *.^name eq "Q::ParameterList",
    $statementlist where *.^name eq "Q::StatementList",
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
    $parameterlist where *.^name eq "Q::ParameterList",
    $statementlist where *.^name eq "Q::StatementList",
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
    $contents where *.^name.starts-with("Q::Regex::"),
) is export {
    _007::Value.new(:type(TYPE<Regex>), slots => {
        :$contents,
    });
}

sub is-regex($v) is export {
    $v ~~ _007::Value && is-instance($v, TYPE<Regex>);
}

sub regex-parse(Str $str, $fragment, Int $last-index is copy) {
    when $fragment.^name eq "Q::Regex::Str" {
        my $value = $fragment.contents.native-value;
        my $slice = $str.substr($last-index, $value.chars);
        return Nil if $slice ne $value;
        return $last-index + $value.chars;
    }
    #when Q::Regex::Identifier {
    #    die "Unhandled regex fragment";
    #}
    #when Q::Regex::Call {
    #    die "Unhandled regex fragment";
    #}
    when $fragment.^name eq "Q::Regex::Group" {
        for $fragment.fragments -> $group-fragment {
            with regex-parse($str, $group-fragment, $last-index) {
                $last-index = $_;
            } else {
                return Nil;
            }
        }
        return $last-index;
    }
    when $fragment.^name eq "Q::Regex::ZeroOrOne" {
        with regex-parse($str, $fragment.fragment, $last-index) {
            return $_;
        } else {
            return $last-index;
        }
    }
    when $fragment.^name eq "Q::Regex::OneOrMore" {
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
    when $fragment.^name eq "Q::Regex::ZeroOrMore" {
        loop {
            with regex-parse($str, $fragment.fragment, $last-index) {
                $last-index = $_;
            } else {
                last;
            }
        }
        return $last-index;
    }
    when $fragment.^name eq "Q::Regex::Alternation" {
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
