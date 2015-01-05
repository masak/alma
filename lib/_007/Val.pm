role Val {}

role Val::None does Val {
    method Str {
        "None"
    }
}

role Val::Int does Val {
    has Int $.value;

    method Str {
        $.value.Str
    }
}

role Val::Str does Val {
    has Str $.value;

    method Str {
        $.value
    }
}

role Val::Array does Val {
    has @.elements;

    method Str {
        '[' ~ @.elements>>.Str.join(', ') ~ ']'
    }
}

role Q::Parameters { ... }
role Q::Statements { ... }

role Val::Block does Val {
    has $.parameters = Q::Parameters.new;
    has $.statements = Q::Statements.new;
    has $.outer-frame;

    method Str { "<block>" }
}

role Val::Sub does Val::Block {
    has $.name;

    method Str { "<sub>" }
}

role Val::Macro does Val::Sub {
    method Str { "<macro>" }
}

role Val::Sub::Builtin does Val::Sub {
    has $.code;

    method new($code) { self.bless(:$code) }
}
