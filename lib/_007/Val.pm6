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

our $global-object-id = 0;

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
        if $.type ~~ Val::Type {
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
    has _007::Value $.static-lexpad is rw where &is-dict = make-dict();
    has _007::Value $.outer-frame where &is-dict;

    submethod BUILD {
        die "Old class Val::Dict -- do not use anymore";
    }

    method new-builtin(&hook, Str $name, $parameterlist, $statementlist) {
        die "Old class Val::Dict, called from Builtins.pm6 -- do not use anymore";
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
        sprintf "(%s)", get-all-array-elements($.parameterlist.parameters)».identifier».name.join(", ");
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
        when Val::Regex { .quoted-Str }
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
