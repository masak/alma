class X::Uninstantiable is Exception {
    has Str $.name;

    method message() { "<type {$.name}> is abstract and uninstantiable"; }
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

### ### NoneType
###
### A type with only one value, indicating the lack of a value where one was
### expected.
###
### It is the value variables have that haven't been assigned to:
###
###     my empty;
###     say(empty);         # --> `None`
###
### It is also the value returned from a subroutine that didn't explicitly
### return a value:
###
###     sub noreturn() {
###     }
###     say(noreturn());    # --> `None`
###
### Finally, it's found in various places in the Q hierarchy to indicate that
### a certain child element is not present. For example, a `my` declaration
### can have an assignment attached to it, in which case its `expr` property
### is a `Q::Expr` &mdash; but if no assignment is present, the `expr`
### property is the value `None`.
###
###     say(type((quasi @ Q::Statement { my x = 2 }).expr)); # --> `<type Q::Literal::Int>`
###     say(type((quasi @ Q::Statement { my x; }).expr));    # --> `<type NoneType>`
###
### The value `None` is falsy, stringifies to `None`, and doesn't numify.
###
###     say(!!None);        # --> `False`
###     say(str(None));     # --> `None`
###     say(int(None));     # <ERROR X::TypeCheck>
###
### Since `None` is often used as a default, there's an operator `infix:<//>`
### that evaluates its right-hand side if it finds `None` on the left:
###
###     say(None // "default");     # --> `default`
###     say("value" // "default");  # --> `value`
###
class Val::NoneType does Val {
    method truthy {
        False
    }
}

constant NONE is export = Val::NoneType.new;

### ### Bool
###
### A type with two values, `True` and `False`. These are often the result
### of comparisons or match operations, such as `infix:<==>` or `infix:<~~>`.
###
###     say(2 + 2 == 5);        # --> `False`
###     say(7 ~~ Int);          # --> `True`
###
### In 007 as in many other dynamic languages, it's not necessary to use
### `True` or `False` values directly in conditions such as `if` statements
### or `while` loops. *Any* value can be used, and there's always a way
### for each type to convert any of its values to a boolean value:
###
###     sub check(value) {
###         if value {
###             say("truthy");
###         }
###         else {
###             say("falsy");
###         }
###     }
###     check(None);            # --> `falsy`
###     check(False);           # --> `falsy`
###     check(0);               # --> `falsy`
###     check("");              # --> `falsy`
###     check([]);              # --> `falsy`
###     check({});              # --> `falsy`
###     # all other values are truthy
###     check(True);            # --> `truthy`
###     check(42);              # --> `truthy`
###     check("James");         # --> `truthy`
###     check([0, 0, 7]);       # --> `truthy`
###     check({ name: "Jim" }); # --> `truthy`
###
### Similarly, when applying the `infix:<||>` and `infix:<&&>` macros to
### some expressions, the result isn't coerced to a boolean value, but
### instead the last value that needed to be evaluated is returned as-is:
###
###     say(1 || 2);            # --> `1`
###     say(1 && 2);            # --> `2`
###     say(None && "!");       # --> `None`
###     say(None || "!");       # --> `!`
###
class Val::Bool does Val {
    has Bool $.value;

    method truthy {
        $.value;
    }
}

### ### Int
###
### An whole number value, such as -8, 0, or 16384.
###
### Implementations are required to represent `Int` values either as 32-bit
### or as arbitrary-precision bigints.
###
### The standard arithmetic operations are defined in the language, with the
### notable exception of division.
###
###     say(-7);                # --> `-7`
###     say(3 + 2);             # --> `5`
###     say(3 * 2);             # --> `6`
###     say(3 % 2);             # --> `1`
###
### Division is not defined, because there's no sensible thing to return for
### something like `3 / 2`. Returning `1.5` is not an option, because the
### language does not have a built-in rational or floating-point type.
### Returning `1` (truncating to an integer) would be possible but
### unsatisfactory and a source of confusion.
###
### There are also a few methods defined on `Int`:
###
###     say((-7).abs());        # --> `7`
###     say(97.chr());          # --> `a`
###
class Val::Int does Val {
    has Int $.value;

    method truthy {
        ?$.value;
    }
}

### ### Str
###
### A piece of text. Strings are frequent whenever a program does text-based
### input/output. Since this language cares a lot about parsing, strings occur
### a lot.
###
### A number of useful operators are defined to work with strings:
###
###     say("James" ~ " Bond"); # --> `James Bond`
###     say("tap" x 3);         # --> `taptaptap`
###
### Besides which, the `Str` type also carries many useful methods:
###
###     say("x".ord());                         # --> `120`
###     say("James".chars());                   # --> `5`
###     say("Bond".uc());                       # --> `BOND`
###     say("Bond".lc());                       # --> `bond`
###     say("  hi   ".trim());                  # --> `hi`
###     say("1,2,3".split(","));                # --> `["1", "2", "3"]`
###     say([4, 5].join(":"));                  # --> `4:5`
###     say("a fool's errand".index("foo"));    # --> `2`
###     say("abcd".substr(1, 2));               # --> `bc`
###     say("abcd".prefix(3));                  # --> `abc`
###     say("abcd".suffix(2));                  # --> `cd`
###     say("James Bond".contains("s B"));      # --> `True`
###     say("James".charat(2));                 # --> `m`
###
class Val::Str does Val {
    has Str $.value;

    method quoted-Str {
        q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]
    }

    method truthy {
        ?$.value;
    }
}

### ### Regex
###
### A regex. As a runtime value, a regex is like a black box that can be put
### to work matching strings or parts of strings. Its main purpose is
### to let us know whether the string matches the pattern described in the
### regex. In other words, it returns `True` or `False`.
###
### (Regexes are currently under development, and are hidden behind a feature
### flag for the time being: `FLAG_007_REGEX`.)
###
### A few methods are defined on regexes:
###
###     say(/"Bond"/.fullmatch("J. Bond"));     # --> `False`
###     say(/"Bond"/.search("J. Bond"));        # --> `True`
###
class Val::Regex does Val {
    has Val::Str $.contents;

    method quoted-Str {
        "/" ~ $.contents.quoted-Str ~ "/"
    }
}

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

class Val::Object does Val {
    has %.properties{Str};
    has $.id = $global-object-id++;

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "\{...\}";
        }
        return '{' ~ %.properties.map({
            my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                ?? .key
                !! Val::Str.new(value => .key).quoted-Str;
            "{$key}: {.value.quoted-Str}"
        }).sort.join(', ') ~ '}';
    }

    method truthy {
        ?%.properties
    }
}

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
        if $.type ~~ Val::Object {
            return $.type.new(:@properties);
        }
        elsif $.type ~~ Val::Int | Val::Str {
            return $.type.new(:value(@properties[0].value.value));
        }
        elsif $.type ~~ Val::Array {
            return $.type.new(:elements(@properties[0].value.elements));
        }
        elsif $.type ~~ Val::Type {
            return $.type.new(:type(@properties[0].value.type));
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

class Val::Block does Val {
    has $.parameterlist;
    has $.statementlist;
    has Val::Object $.static-lexpad is rw = Val::Object.new;
    has Val::Object $.outer-frame;

    method pretty-parameters {
        sprintf "(%s)", $.parameterlist.parameters.elements».identifier».name.join(", ");
    }
}

class Val::Sub is Val::Block {
    has Val::Str $.name;
    has &.hook = Callable;

    method new-builtin(&hook, Str $name, $parameterlist, $statementlist) {
        self.bless(:name(Val::Str.new(:value($name))), :&hook, :$parameterlist, :$statementlist);
    }

    method escaped-name {
        sub escape-backslashes($s) { $s.subst(/\\/, "\\\\", :g) }
        sub escape-less-thans($s) { $s.subst(/"<"/, "\\<", :g) }

        return $.name.value
            unless $.name.value ~~ /^ (prefix | infix | postfix) ':' (.+) /;

        return "{$0}:<{escape-less-thans escape-backslashes $1}>"
            if $1.contains(">") && $1.contains("»");

        return "{$0}:«{escape-backslashes $1}»"
            if $1.contains(">");

        return "{$0}:<{escape-backslashes $1}>";
    }

    method Str { "<sub {$.escaped-name}{$.pretty-parameters}>" }
}

class Val::Macro is Val::Sub {
    method Str { "<macro {$.escaped-name}{$.pretty-parameters}>" }
}

class Val::Exception does Val {
    has Val::Str $.message;
}

class Helper {
    our sub Str($_) {
        when Val::NoneType { "None" }
        when Val::Bool { .value.Str }
        when Val::Int { .value.Str }
        when Val::Str { .value }
        when Val::Regex { .quoted-Str }
        when Val::Array { .quoted-Str }
        when Val::Object { .quoted-Str }
        when Val::Type { "<type {.name}>" }
        when Val::Macro { "<macro {.escaped-name}{.pretty-parameters}>" }
        when Val::Sub { "<sub {.escaped-name}{.pretty-parameters}>" }
        when Val::Block { "<block {.pretty-parameters}>" }
        when Val::Exception { "Exception \{message: {.message.quoted-Str}\}" }
        default {
            my $self = $_;
            die "Unexpected type -- some invariant must be broken"
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
