role Val {
    method truthy {
        True
    }
}

role Val::None does Val {
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

role Val::Int does Val {
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

role Val::Str does Val {
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

role Val::Array does Val {
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

role Q::ParameterList { ... }
role Q::StatementList { ... }

our $global-object-id = 0;

role Val::Object does Val {
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

role Val::Block does Val {
    has $.parameterlist is rw = Q::ParameterList.new;
    has $.statementlist = Q::StatementList.new;
    has %.static-lexpad;
    has $.outer-frame;

    method quoted-Str {
        self.Str
    }

    method pretty-params {
        sprintf "(%s)", $.parameterlist».name.join(", ");
    }
    method Str { "<block {$.pretty-params}>" }
}

role Val::Sub does Val::Block {
    has $.name;

    method quoted-Str {
        self.Str
    }

    method Str { "<sub {$.name}{$.pretty-params}>" }
}

role Val::Macro does Val::Sub {
    method quoted-Str {
        self.Str
    }

    method Str { "<macro {$.name}{$.pretty-params}>" }
}

role Val::Sub::Builtin does Val::Sub {
    has $.code;
    has $.qtype;
    has $.assoc;
    has %.precedence;

    method new($name, $code, :$qtype, :$assoc, :%precedence, :$parameterlist) {
        self.bless(:$name, :$code, :$qtype, :$assoc, :%precedence, :$parameterlist)
    }
}
