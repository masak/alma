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
###     say(type((quasi { my x = 2; }).expr));  # --> `<type Q::Expr>`
###     say(type((quasi { my x; }).expr));      # --> `<type NoneType>`
###
### The value `None` is falsy, stringifies to `"None"`, and doesn't numify.
###
###     say(!!None);        # --> `False`
###     say(str(None));     # --> `"None"`
###     say(int(None));     # <ERROR>
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
###     check(True);            # ---> `truthy`
###     check(42);              # ---> `truthy`
###     check("James");         # ---> `truthy`
###     check([0, 0, 7]);       # ---> `truthy`
###     check({ name: "Jim" }); # ---> `truthy`
###
### Similarly, when applying the `infix:<||>` and `infix:<&&>` macros to
### some expressions, the result isn't coerced to a boolean value, but
### instead the last value that needed to be evaluated is returned as-is:
###
###     say(1 || 2);            # ---> `1`
###     say(1 && 2);            # ---> `2`
###     say(None && "!");       # ---> `None`
###     say(None || "!");       # ---> `!`
###
class Val::Bool does Val {
    has Bool $.value;

    method truthy {
        $.value;
    }
}

class Val::Int does Val {
    has Int $.value;

    method truthy {
        ?$.value;
    }
}

class Val::Str does Val {
    has Str $.value;

    method quoted-Str {
        q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]
    }

    method truthy {
        ?$.value;
    }
}

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
