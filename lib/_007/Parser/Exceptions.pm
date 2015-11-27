class X::String::Newline is Exception {
    method message { "Found a newline inside a string literal" }
}

class X::PointyBlock::SinkContext is Exception {
    method message { "Pointy blocks cannot occur on the statement level" }
}

class X::Trait::Conflict is Exception {
    has Str $.t1;
    has Str $.t2;

    method message { "Traits '$.t1' and '$.t2' cannot coexist on the same routine" }
}

class X::Op::Nonassociative is Exception {
    has Str $.op1;
    has Str $.op2;

    method message {
        my $name1 = $.op1.type.substr(1, *-1);
        my $name2 = $.op2.type.substr(1, *-1);
        "'$name1' and '$name2' do not associate -- please use parentheses"
    }
}

class X::Trait::IllegalValue is Exception {
    has Str $.trait;
    has Str $.value;

    method message { "The value '$.value' is not compatible with the trait '$.trait'" }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

class X::Precedence::Incompatible is Exception {
    method message { "Trying to relate a pre/postfix operator with an infix operator" }
}

class X::Macro::Postdeclared is Exception {
    has Str $.name;

    method message { "Macro $.name declared after it was called" }
}

class X::Property::NotDeclared is Exception {
    has Str $.type;
    has Str $.property;

    method message { "The property '$.property' is not defined on type '$.type'" }
}

class X::Property::Required is Exception {
    has Str $.type;
    has Str $.property;

    method message { "The property '$.property' is required on type '$.type'" }
}
