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

role Val::Block does Val {
    has $.parameters;
    has $.statements;
    has $.outer-frame;

    method Str { "<block>" }
}

role Val::Sub does Val::Block {
    has $.name;

    method Str { "<sub>" }
}

role Val::Sub::Builtin does Val::Sub {
    has $.code;

    method new($code) { self.bless(:$code) }
}
