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

class Helper {
    our sub Str($_) {
        when Val::Type { "<type {.name}>" }
        default {
            my $self = $_;
            my $name = .^name;
            die "Unexpected type -- some invariant must be broken"
                unless $name ~~ /^ "Q::"/;    # type not introduced yet; can't typecheck

            sub aname($attr) { $attr.name.substr(2) }
            sub avalue($attr, $obj) {
                my $value = $attr.get_value($obj);
                # XXX: this is a temporary fix until we patch Q.Unquote's qtype to be an identifier
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
