use MONKEY-SEE-NO-EVAL;

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
###     func noreturn() {
###     }
###     say(noreturn());    # --> `None`
###
### Finally, it's found in various places in the Q hierarchy to indicate that
### a certain child element is not present. For example, an `if` statement
### doesn't always have an `else` statement. When it doesn't, the `.else`
### property is set to `None`.
###
###     say(type((quasi<Q.Statement> { if 1 {} }).else)); # --> `<type NoneType>`
###
### The value `None` is falsy, stringifies to `None`, and doesn't numify.
###
###     say(!!None);        # --> `False`
###     say(~None);         # --> `None`
###     say(+None);         # <ERROR X::TypeCheck>
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
###     func check(value) {
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
### You can join together strings using the concatenation operator:
###
###     say("James" ~ " Bond"); # --> `James Bond`
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
            my $value = $fragment.contents.value;
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

### ### Tuple
###
### An immutable sequence of values. A tuple contains zero or more elements,
### indexed from `0` up to `size - 1`, where `size` is the number of
### elements.
###
### The syntax for creating a tuple term consists of parentheses as delimiters
### and commas as separators, but since `(value)` already means mathematical
### grouping, you have to have a trailing comma if you want to make a
### one-element tuple:
###
###     say( () );              # --> `()`
###     say( (1) );             # --> `1`
###     say( (1,) );            # --> `(1,)`
###     say( (1, 2) );          # --> `(1, 2)`
###     say( (1, 2, 3) );       # --> `(1, 2, 3)`
###
### The `.size` method gives you the length (number of elements) of the
### tuple:
###
###     say(().size());         # --> `0`
###     say((1, 2, 3).size());  # --> `3`
###
### Tuples are immutable, so the mutation methods supported for arrays
### (push, pop, shift, unshift) do not exist on tuples.
###
### You can also *transform* an entire tuple, either by mapping
### each element through a function, or by filtering each element
### through a predicate function:
###
###     my numbers = (1, 2, 3, 4, 5);
###     say(numbers.map(func (e) { return e * 2 }));     # --> `(2, 4, 6, 8, 10)`
###     say(numbers.filter(func (e) { return e %% 2 })); # --> `(2, 4)`
###
class Val::Tuple does Val {
    has @.elements;

    method quoted-Str {
        if %*stringification-seen{self.WHICH}++ {
            return "(...)";
        }
        return @.elements == 1
            ?? "(" ~ @.elements[0] ~ ",)"
            !! "(" ~ @.elements>>.quoted-Str.join(", ") ~ ")";
    }

    method truthy {
        ?$.elements;
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
###         greet: func () {
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
                !! Val::Str.new(value => .key).quoted-Str;
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
###     my q = new Q.Literal.Int { value: 42 };
###     say(q ~~ Q.Literal.Int);    # --> `True`
###     say(q ~~ Q.Literal);        # --> `True`
###     say(q ~~ Q);                # --> `True`
###     say(q ~~ Int);              # --> `False`
###
### If you want *exact* type matching (which isn't a very OO thing to want),
### consider using infix:<==> on the respective type objects instead:
###
###     my q = new Q.Literal.Str { value: "Bond" };
###     say(type(q) == Q.Literal.Str);      # --> `True`
###     say(type(q) == Q.Literal);          # --> `False`
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
        elsif $.type ~~ Val::Int | Val::Str {
            return $.type.new(:value(@properties[0].value.value));
        }
        elsif $.type ~~ Val::Array | Val::Tuple {
            return $.type.new(:elements(@properties[0].value.elements));
        }
        elsif $.type ~~ Val::Type {
            my $name = @properties[0].value;
            return $.type.new(:type(EVAL qq[class :: \{
                method attributes \{ () \}
                method ^name(\$) \{ "{$name}" \}
            \}]));
        }
        elsif $.type ~~ Val::NoneType || $.type ~~ Val::Bool || is-role($.type) {
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
    has Val::Str $.name;
    has &.hook = Callable;
    has $.parameterlist;
    has $.statementlist;
    has Val::Object $.static-lexpad is rw = Val::Object.new;
    has Val::Object $.outer-frame;

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

### ### Exception
###
### An exception. Represents an error condition, or some other way control
### flow couldn't continue normally.
###
class Val::Exception does Val {
    has Val::Str $.message;
}

### ### Location
###
### A changeable piece of memory, typically corresponding to a lexical variable.
###
class Val::Location does Val {
}

class Helper {
    our sub Str($_) {
        when Val::NoneType { "None" }
        when Val::Bool { .value.Str }
        when Val::Int { .value.Str }
        when Val::Str { .value }
        when Val::Regex { .quoted-Str }
        when Val::Array { .quoted-Str }
        when Val::Tuple { .quoted-Str }
        when Val::Object { .quoted-Str }
        when Val::Type { "<type {.name}>" }
        when Val::Macro { "<macro {.escaped-name}{.pretty-parameters}>" }
        when Val::Func { "<sub {.escaped-name}{.pretty-parameters}>" }
        when Val::Exception { "Exception \{message: {.message.quoted-Str}\}" }
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
