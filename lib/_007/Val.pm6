use _007::Value;
use MONKEY-SEE-NO-EVAL;

class X::Uninstantiable is Exception {
    has Str $.name;
    has Bool $.abstract;

    method message() { "<type {$.name}> is {$.abstract ?? "abstract and " !! ""}uninstantiable" }
}

class Helper { ... }

role Val {
    method truthy { True }
    method attributes { self.^attributes }
    method quoted-Str { self.Str }

    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }
}

### ### Object
###
### The top type of 007. A featureless object. Everything inherits from this type.
class Val::Object does Val {
    submethod BUILD {
        die "Old class Val::Object -- do not use anymore";
    }

    method truthy {
        True
    }
}

### ### Regex
###
### A regex. As a runtime value, a regex is like a black box that can be put
### to work matching strings or parts of strings. Its main purpose is
### to let us know whether the string matches the pattern described in the
### regex. In other words, it returns `true` or `false`.
###
### (Regexes are currently under development, and are hidden behind a feature
### flag for the time being: `FLAG_007_REGEX`.)
###
### A few methods are defined on regexes:
###
###     say(/"Bond"/.fullmatch("J. Bond"));     # --> `false`
###     say(/"Bond"/.search("J. Bond"));        # --> `true`
###
class Val::Regex does Val {
    # note: a regex should probably keep its lexpad or something to resolve calls&identifiers
    has $.contents;

    method search(Str $str) {
        for ^$str.chars {
            return True with parse($str, $.contents, $_);
        }
        return False;
    }

    method fullmatch(Str $str) {
        return ?($_ == $str.chars with parse($str, $.contents, 0));
    }

    sub parse($str, $fragment, Int $last-index is copy) {
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
                with parse($str, $group-fragment, $last-index) {
                    $last-index = $_;
                } else {
                    return Nil;
                }
            }
            return $last-index;
        }
        when $fragment.^name eq "Q::Regex::ZeroOrOne" {
            with parse($str, $fragment.fragment, $last-index) {
                return $_;
            } else {
                return $last-index;
            }
        }
        when $fragment.^name eq "Q::Regex::OneOrMore" {
            # XXX technically just a fragment+a ZeroOrMore
            return Nil unless $last-index = parse($str, $fragment.fragment, $last-index);
            loop {
                with parse($str, $fragment.fragment, $last-index) {
                    $last-index = $_;
                } else {
                    last;
                }
            }
            return $last-index;
        }
        when $fragment.^name eq "Q::Regex::ZeroOrMore" {
            loop {
                with parse($str, $fragment.fragment, $last-index) {
                    $last-index = $_;
                } else {
                    last;
                }
            }
            return $last-index;
        }
        when $fragment.^name eq "Q::Regex::Alternation" {
            for $fragment.alternatives -> $alternative {
                with parse($str, $alternative, $last-index) {
                    return $_;
                }
            }
            return Nil;
        }
        default {
            die "No handler for {$fragment.^name}";
        }
    }
}

### ### Array
###
### A mutable sequence of values. An array contains zero or more elements,
### indexed from `0` up to `size - 1`, where `size` is the number of
### elements.
###
### Besides creating an array using an array term, one can also use the
### "upto" prefix operator, which creates an array where the elemens equal the
### indices:
###
###     say(["a", "b", "c"]);   # --> `["a", "b", "c"]`
###     say(^3);                # --> `[0, 1, 2]`
###
### Another array constructor which creates entirely new arrays out of old ones
### (and leave the old ones unchanged) is concatenation:
###
###     say([1, 2].concat([3, 4])); # --> `[1, 2, 3, 4]`
###
### Sorting, shuffling, and reversing an array also leave the original
### array unchanged:
###
###     my a = [6, 4, 5];
###     say(a.reverse());           # --> `[5, 4, 6]`
###     say(a);                     # --> `[6, 4, 5]`
###     say(a.sort());              # --> `[4, 5, 6]`
###     say(a);                     # --> `[6, 4, 5]`
###     say(a.shuffle().sort());    # --> `[4, 5, 6]`
###     say(a);                     # --> `[6, 4, 5]`
###
### The `.size` method gives you the length (number of elements) of the
### array:
###
###     say([].size());         # --> `0`
###     say([1, 2, 3].size());  # --> `3`
###
### Some common methods use the fact that the array is mutable:
###
###     my a = [1, 2, 3];
###     a.push(4);
###     say(a);                 # --> `[1, 2, 3, 4]`
###     my x = a.pop();
###     say(x);                 # --> `4`
###     say(a);                 # --> `[1, 2, 3]`
###
###     my a = ["a", "b", "c"];
###     my y = a.shift();
###     say(y);                 # --> `a`
###     say(a);                 # --> `["b", "c"]`
###     a.unshift(y);
###     say(a);                 # --> `["a", "b", "c"]`
###
### You can also *transform* an entire array, either by mapping
### each element through a function, or by filtering each element
### through a predicate function:
###
###     my numbers = [1, 2, 3, 4, 5];
###     say(numbers.map(func (e) { return e * 2 }));     # --> `[2, 4, 6, 8, 10]`
###     say(numbers.filter(func (e) { return e %% 2 })); # --> `[2, 4]`
###
class Val::Array does Val {
    has @.elements;

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "[...]";
        }
        return "[" ~ @.elements>>.quoted-Str.join(', ') ~ "]";
    }

    method truthy {
        ?$.elements
    }
}

our $global-object-id = 0;

### ### Dict
###
### A mutable unordered collection of key/value entries. A dict
### contains zero or more such entries, each with a unique string
### name.
###
### The way to create a dict from scratch is to use the dict term
### syntax:
###
###     my d1 = { foo: 42 };        # autoquoted key
###     my d2 = { "foo": 42 };      # string key
###     say(d1 == d2);              # --> `true`
###
### There's a way to extract an array of a dict's keys. The order of the keys in
### this list is not defined and may even change from call to call.
###
###     my d3 = {
###         one: 1,
###         two: 2,
###         three: 3
###     };
###     say(d3.keys().sort());      # --> `["one", "three", "two"]`
###
### You can also ask whether an entry exists in a dict.
###
###     my d4 = {
###         foo: 42,
###         bar: none
###     };
###     say(d4.has("foo"));        # --> `true`
###     say(d4.has("bar"));        # --> `true`
###     say(d4.has("bazinga"));    # --> `false`
###
### Note that the criterion is whether the *entry* exists, not whether the
### corresponding value is defined.
###
class Val::Dict does Val {
    has %.properties{Str};

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "\{...\}";
        }
        return '{' ~ %.properties.map({
            my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                ?? .key
                !! make-str(.key).quoted-Str;
            "{$key}: {.value.quoted-Str}"
        }).sort.join(', ') ~ '}';
    }

    method truthy {
        ?%.properties
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
### 007 comes with a number of built-in types: `None`, `Bool`, `Int`,
### `Str`, `Array`, `Dict`, `Regex`, `Type`, `Block`, `Sub`, `Macro`,
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
###     say(42 ~~ Int);         # --> `true`
###     say(42 ~~ Str);         # --> `false`
###
### The `infix:<~~>` operator respects subtyping, so checking against a
### wider type also gives a `true` result:
###
###     my q = new Q.Literal.Int { value: 42 };
###     say(q ~~ Q.Literal.Int);    # --> `true`
###     say(q ~~ Q.Literal);        # --> `true`
###     say(q ~~ Q);                # --> `true`
###     say(q ~~ Int);              # --> `false`
###
### If you want *exact* type matching (which isn't a very OO thing to want),
### consider using infix:<==> on the respective type objects instead:
###
###     my q = new Q.Literal.Str { value: "Bond" };
###     say(type(q) == Q.Literal.Str);      # --> `true`
###     say(type(q) == Q.Literal);          # --> `false`
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
        if $.type ~~ Val::Dict {
            return $.type.new(:@properties);
        }
        elsif $.type ~~ Val::Array {
            return $.type.new(:elements(@properties[0].value.elements));
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
        $.type.^name.subst(/^ "Val::"/, "").subst(/"::"/, ".", :g);
    }
}

### ### Func
###
### A function. When you define a function in 007, the value of the
### name bound is a `Func` object.
###
###     func agent() {
###         return "Bond";
###     }
###     say(agent);             # --> `<func agent()>`
###
### Subroutines are mostly distinguished by being *callable*, that is, they
### can be called at runtime by passing some values into them.
###
###     func add(x, y) {
###         return x + y;
###     }
###     say(add(2, 5));         # --> `7`
###
class Val::Func does Val {
    has _007::Value $.name where &is-str;
    has &.hook = Callable;
    has $.parameterlist;
    has $.statementlist;
    has Val::Dict $.static-lexpad is rw = Val::Dict.new;
    has Val::Dict $.outer-frame;

    method new-builtin(&hook, Str $name, $parameterlist, $statementlist) {
        self.bless(:name(make-str($name)), :&hook, :$parameterlist, :$statementlist);
    }

    method escaped-name {
        sub escape-backslashes($s) { $s.subst(/\\/, "\\\\", :g) }
        sub escape-less-thans($s) { $s.subst(/"<"/, "\\<", :g) }

        return $.name.native-value
            unless $.name.native-value ~~ /^ (prefix | infix | postfix) ':' (.+) /;

        return "{$0}:<{escape-less-thans escape-backslashes $1}>"
            if $1.contains(">") && $1.contains("»");

        return "{$0}:«{escape-backslashes $1}»"
            if $1.contains(">");

        return "{$0}:<{escape-backslashes $1}>";
    }

    method pretty-parameters {
        sprintf "(%s)", $.parameterlist.parameters.elements».identifier».name.join(", ");
    }

    method Str { "<func {$.escaped-name}{$.pretty-parameters}>" }
}

### ### Macro
###
### A macro. When you define a macro in 007, the value of the name bound
### is a macro object.
###
###     macro agent() {
###         return quasi { "Bond" };
###     }
###     say(agent);             # --> `<macro agent()>`
###
class Val::Macro is Val::Func {
    method Str { "<macro {$.escaped-name}{$.pretty-parameters}>" }
}

class Helper {
    our sub Str($_) {
        when Val::Object { "<object>" }
        when Val::Regex { .quoted-Str }
        when Val::Array { .quoted-Str }
        when Val::Dict { .quoted-Str }
        when Val::Type { "<type {.name}>" }
        when Val::Macro { "<macro {.escaped-name}{.pretty-parameters}>" }
        when Val::Func { "<sub {.escaped-name}{.pretty-parameters}>" }
        default {
            my $self = $_;
            my $name = .^name;
            die "Unexpected type -- some invariant must be broken"
                unless $name ~~ /^ "Q::"/;    # type not introduced yet; can't typecheck

            sub aname($attr) { $attr.name.substr(2) }
            sub avalue($attr, $obj) {
                my $value = $attr.get_value($obj);
                # XXX: this is a temporary fix until we patch Q::Unquote's qtype to be an identifier
                $value
                    ?? $value.quoted-Str
                    !! $value.^name.subst(/"::"/, ".", :g);
            }

            $name.=subst(/"::"/, ".", :g);

            my @attrs = $self.attributes;
            if @attrs == 1 {
                return "$name { avalue(@attrs[0], $self) }";
            }
            sub keyvalue($attr) { aname($attr) ~ ": " ~ avalue($attr, $self) }
            my $contents = @attrs.map(&keyvalue).join(",\n").indent(4);
            return "$name \{\n$contents\n\}";
        }
    }
}
