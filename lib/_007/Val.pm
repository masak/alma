role Val {
    method truthy {
        True
    }

    method attributes {
        self.^attributes
    }
}

class Val::None does Val {
    method quoted-Str {
        self.Str
    }

    method Str {
        "None"
    }

    method truthy {
        False
    }
}

class Val::Int does Val {
    has Int $.value;

    method quoted-Str {
        self.Str
    }

    method Str {
        $.value.Str
    }

    method truthy {
        ?$.value;
    }
}

class Val::Str does Val {
    has Str $.value;

    method quoted-Str {
        q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]
    }

    method Str {
        $.value
    }

    method truthy {
        ?$.value;
    }
}

class Val::Array does Val {
    has @.elements;

    method quoted-Str {
        "[" ~ @.elements>>.quoted-Str.join(', ') ~ "]"
    }

    method Str {
        self.quoted-Str
    }

    method truthy {
        ?$.elements
    }
}

our $global-object-id = 0;

class Val::Object does Val {
    has %.properties{Str};
    has $.id = $global-object-id++;

    method Str {
        '{' ~ %.properties.map({
            my $key = .key ~~ /^<!before \d> [\w+]+ % '::'$/
                ?? .key
                !! Val::Str.new(value => .key).quoted-Str;
            "{$key}: {.value.quoted-Str}"
        }).sort.join(', ') ~ '}'
    }

    method quoted-Str {
        self.Str
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
        else {
            return $.type.new(|%(@properties));
        }
    }

    method Str { "<type {$.type.^name.subst(/^ "Val::"/, "").subst(/"::Builtin" $/, "")}>" }
}

class Val::Block does Val {
    has $.parameterlist is rw;
    has $.statementlist;
    has %.static-lexpad;
    has $.outer-frame;

    method quoted-Str {
        self.Str
    }

    method pretty-parameters {
        sprintf "(%s)", $.parameterlist.parameters.elements».identifier».name.join(", ");
    }
    method Str { "<block {$.pretty-parameters}>" }
}

class Val::Sub is Val::Block {
    has Str $.name;

    method quoted-Str {
        self.Str
    }

    method Str { "<sub {$.name}{$.pretty-parameters}>" }
}

class Val::Macro is Val::Sub {
    method quoted-Str {
        self.Str
    }

    method Str { "<macro {$.name}{$.pretty-parameters}>" }
}
