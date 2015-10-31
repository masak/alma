role Val {
    method truthy {
        True
    }
}

role Val::None does Val {
    method Str {
        "None"
    }

    method truthy {
        False
    }
}

role Val::Int does Val {
    has Int $.value;

    method Str {
        $.value.Str
    }

    method truthy {
        ?$.value;
    }
}

role Val::Str does Val {
    has Str $.value;

    method Str {
        $.value
    }

    method quoted-Str {
        q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]
    }

    method truthy {
        ?$.value;
    }
}

role Val::Array does Val {
    has @.elements;

    method Str {
        sub strarray($_) {
            when Val::Str { .quoted-Str }
            when Val::Array { "[" ~ .elements>>.&strarray.join(', ') ~ "]" }
            .Str;
        }

        strarray(self);
    }

    method truthy {
        ?$.elements
    }
}

role Q::ParameterList { ... }
role Q::StatementList { ... }

role Val::Block does Val {
    has $.parameterlist = Q::ParameterList.new;
    has $.statementlist = Q::StatementList.new;
    has %.static-lexpad;
    has $.outer-frame;

    method pretty-params {
        sprintf "(%s)", $.parameterlist».name.join(", ");
    }
    method Str { "<block {$.pretty-params}>" }
}

role Val::Sub does Val::Block {
    has $.name;

    method Str { "<sub {$.name}{$.pretty-params}>" }
}

role Val::Macro does Val::Sub {
    method Str { "<macro {$.name}{$.pretty-params}>" }
}

role Val::Sub::Builtin does Val::Sub {
    has $.code;

    method new($name, $code) { self.bless(:$name, :$code) }
}
