use MONKEY-SEE-NO-EVAL;

class X::Uninstantiable is Exception {
    has Str $.name;

    method message() { "<type {$.name}> is abstract and uninstantiable"; }
}

class Helper { ... }

class _007::Type {
    has $.name;

    method attributes { () }

    method quoted-Str { self.Str }
    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }
}

constant TYPE = hash(<Type Int Str Array NoneType Bool>.map(-> $name {
    $name => _007::Type.new(:$name)
}));

class _007::Object {
    has $.type;

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
        return self.Str;
    }
}

constant NONE is export = _007::Object::Enum.new(:type(TYPE<NoneType>));
constant TRUE is export = _007::Object::Enum.new(:type(TYPE<Bool>));
constant FALSE is export = _007::Object::Enum.new(:type(TYPE<Bool>));

sub truthy($v) {
    $v !=== NONE && $v !=== FALSE
}

sub sevenize($value) is export {
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
    elsif $value ~~ Nil {
        return NONE;
    }
    else {
        die "Tried to sevenize unknown value ", $value.^name;
    }
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
    has _007::Object $.contents;

    method quoted-Str {
        "/" ~ $.contents.quoted-Str ~ "/"
    }
}

our $global-object-id = 0;

### ### Object
###
### A mutable unordered collection of key/value properties. An object
### contains zero or more such properties, each with a unique string
### name.
###
### The way to create an object from scratch is to use the object term
### syntax:
###
###     my o1 = { foo: 42 };        # autoquoted key
###     my o2 = { "foo": 42 };      # string key
###     say(o1 == o2);              # --> `True`
###     my foo = 42;
###     my o3 = { foo };            # property shorthand
###     say(o1 == o3);              # --> `True`
###
###     my o4 = {
###         greet: sub () {
###             return "hi!";
###         }
###     };
###     my o5 = {
###         greet() {               # method shorthand
###             return "hi!";
###         }
###     };
###     say(o4.greet() == o5.greet());  # --> `True`
###
### All of the above will create objects of type `Object`, which is
### the topmost type in the type system. `Object` also has the special
### property that it can accept any set of keys.
###
###     say(type({}));              # --> `<type Object>`
###
### There are also two ways to create a new, similar object from an old one.
###
###     my o6 = {
###         name: "James",
###         job: "librarian"
###     };
###     my o7 = o6.update({
###         job: "secret agent"
###     });
###     say(o7);                    # --> `{job: "secret agent", name: "James"}`
###
###     my o8 = {
###         name: "Blofeld"
###     };
###     my o9 = o8.extend({
###         job: "supervillain"
###     });
###     say(o9);                    # --> `{job: "supervillain", name: "Blofeld"}`
###
### There's a way to extract an array of an object's keys. The order of the keys in
### this list is not defined and may even change from call to call.
###
###     my o10 = {
###         one: 1,
###         two: 2,
###         three: 3
###     };
###     say(o10.keys().sort());     # --> `["one", "three", "two"]`
###
### You can also ask whether a key exists on an object.
###
###     my o11 = {
###         foo: 42,
###         bar: None
###     };
###     say(o11.has("foo"));        # --> `True`
###     say(o11.has("bar"));        # --> `True`
###     say(o11.has("bazinga"));    # --> `False`
###
### Note that the criterion is whether the *key* exists, not whether the
### corresponding value is defined.
###
### Each object has a unique ID, corresponding to references in other
### languages. Comparison of objects happens by comparing keys and values,
### not by reference. If you want to do a reference comparison, you need
### to use the `.id` property:
###
###     my o12 = { foo: 5 };
###     my o13 = { foo: 5 };        # same key/value but different reference
###     say(o12 == o13);            # --> `True`
###     say(o12.id == o13.id);      # --> `False`
###
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
                !! sevenize(.key).quoted-Str;
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
###     say(type({}));          # --> `<type Object>`
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
        if $.type ~~ Val::Object {
            return $.type.new(:@properties);
        }
        elsif $.type ~~ _007::Object {
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

### ### Sub
###
### A subroutine. When you define a subroutine in 007, the value of the
### name bound is a `Sub` object.
###
###     sub agent() {
###         return "Bond";
###     }
###     say(agent);             # --> `<sub agent()>`
###
### Subroutines are mostly distinguished by being *callable*, that is, they
### can be called at runtime by passing some values into them.
###
###     sub add(x, y) {
###         return x + y;
###     }
###     say(add(2, 5));         # --> `7`
###
class Val::Sub is Val {
    has _007::Object $.name;
    has &.hook = Callable;
    has $.parameterlist;
    has $.statementlist;
    has Val::Object $.static-lexpad is rw = Val::Object.new;
    has Val::Object $.outer-frame;

    method new-builtin(&hook, Str $name, $parameterlist, $statementlist) {
        self.bless(:name(sevenize($name)), :&hook, :$parameterlist, :$statementlist);
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

    method pretty-parameters {
        sprintf "(%s)", $.parameterlist.parameters.value».identifier».name.join(", ");
    }

    method Str { "<sub {$.escaped-name}{$.pretty-parameters}>" }
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
class Val::Macro is Val::Sub {
    method Str { "<macro {$.escaped-name}{$.pretty-parameters}>" }
}

### ### Exception
###
### An exception. Represents an error condition, or some other way control
### flow couldn't continue normally.
###
class Val::Exception does Val {
    has _007::Object $.message;
}

class Helper {
    our sub Str($_) {
        when Val::Regex { .quoted-Str }
        when Val::Object { .quoted-Str }
        when Val::Type { "<type {.name}>" }
        when _007::Type { "<type {.name}>" }
        when _007::Object {
            .type === TYPE<NoneType>
                ?? "None"
                !! .type === TYPE<Bool>
                    ?? ($_ === TRUE ?? "True" !! "False")
                    !! .type === TYPE<Array>
                        ?? .quoted-Str
                        !! .value.Str
        }
        when Val::Macro { "<macro {.escaped-name}{.pretty-parameters}>" }
        when Val::Sub { "<sub {.escaped-name}{.pretty-parameters}>" }
        when Val::Exception { "Exception \{message: {.message.quoted-Str}\}" }
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
