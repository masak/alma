use _007::Val;

class X::Control::Return is Exception {
    has $.frame;
    has $.value;
}

class X::Subscript::TooLarge is Exception {
    has $.value;
    has $.length;

    method message() { "Subscript ($.value) too large (array length $.length)" }
}

class X::Subscript::NonInteger is Exception {
}

class X::Subscript::NonString is Exception {
}

class X::ParameterMismatch is Exception {
    has $.type;
    has $.paramcount;
    has $.argcount;

    method message {
        "$.type with $.paramcount parameters called with $.argcount arguments"
    }
}

class X::Property::NotFound is Exception {
    has $.propname;
    has $.type;

    method message {
        "Property '$.propname' not found on object of type $.type"
    }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

class X::Regex::InvalidMatchType is Exception {
    method message { "A regex can only match strings" }
}

class X::_007::RuntimeException is Exception {
    has $.msg;

    method message {
        $.msg.Str;
    }
}

sub aname($attr) { $attr.name.substr(2) }
sub avalue($attr, $obj) { $attr.get_value($obj) }

role Q {
    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }

    method quoted-Str {
        self.Str
    }

    method truthy {
        True
    }

    method attributes {
        sub find($aname) { self.^attributes.first({ $aname eq aname($_) }) }

        self.can("attribute-order")
            ?? self.attribute-order.map({ find($_) })
            !! self.^attributes;
    }
}

role Q::Expr does Q {
}

role Q::Term does Q::Expr {
}

role Q::Literal does Q::Term {
}

class Q::Literal::None does Q::Literal {
    method eval($) { NONE }
}

class Q::Literal::Bool does Q::Literal {
    has Val::Bool $.value;

    method eval($) { $.value }
}

class Q::Literal::Int does Q::Literal {
    has Val::Int $.value;

    method eval($) { $.value }
}

class Q::Literal::Str does Q::Literal {
    has Val::Str $.value;

    method eval($) { $.value }
}

class Q::Identifier does Q::Term {
    has Val::Str $.name;
    has $.frame = NONE;

    method attribute-order { <name> }

    method eval($runtime) {
        return $runtime.get-var($.name.value, $.frame);
    }

    method put-value($value, $runtime) {
        $runtime.put-var(self, $value);
    }
}

class Q::Term::Regex does Q::Term {
    has Val::Str $.contents;

    method eval($runtime) {
        Val::Regex.new(:$.contents);
    }
}

class Q::Term::Array does Q::Term {
    has Val::Array $.elements;

    method eval($runtime) {
        Val::Array.new(:elements($.elements.elements.map(*.eval($runtime))));
    }
}

class Q::Term::Object does Q::Term {
    has Q::Identifier $.type;
    has $.propertylist;

    method eval($runtime) {
        return $runtime.get-var($.type.name.value, $.type.frame).create(
            $.propertylist.properties.elements.map({.key.value => .value.eval($runtime)})
        );
    }
}

class Q::Property does Q {
    has Val::Str $.key;
    has $.value;
}

class Q::PropertyList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.properties = Val::Array.new;
}

role Q::Declaration {
    method is-assignable { False }
}

class Q::Trait does Q {
    has $.identifier;
    has $.expr;

    method attribute-order { <identifier expr> }
}

class Q::TraitList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.traits = Val::Array.new;

    method attribute-order { <traits> }
}

class Q::Term::Sub does Q::Term does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }

    method eval($runtime) {
        my $name = $.identifier ~~ Val::NoneType
            ?? Val::Str.new(:value(""))
            !! $.identifier.name;
        return Val::Sub.new(
            :$name,
            :parameterlist($.block.parameterlist),
            :statementlist($.block.statementlist),
            :static-lexpad($.block.static-lexpad),
            :outer-frame($runtime.current-frame),
        );
    }
}

class Q::Block does Q {
    has $.parameterlist;
    has $.statementlist;
    has Val::Object $.static-lexpad is rw = Val::Object.new;

    method attribute-order { <parameterlist statementlist> }

    method reify($runtime) {
        my Val::Object $outer-frame = $runtime.current-frame;
        Val::Block.new(
            :$.parameterlist,
            :$.statementlist,
            :$.static-lexpad,
            :$outer-frame
        );
    }
}

class Q::Prefix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }

    method eval($runtime) {
        my $e = $.operand.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$e]);
    }
}

class Q::Prefix::Str is Q::Prefix {}

class Q::Prefix::Plus is Q::Prefix {}

class Q::Prefix::Minus is Q::Prefix {}

class Q::Prefix::Not is Q::Prefix {}

class Q::Prefix::Upto is Q::Prefix {}

class Q::Infix does Q::Expr {
    has $.identifier;
    has $.lhs;
    has $.rhs;

    method attribute-order { <identifier lhs rhs> }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$l, $r]);
    }
}

class Q::Infix::Addition is Q::Infix {}

class Q::Infix::Subtraction is Q::Infix {}

class Q::Infix::Multiplication is Q::Infix {}

class Q::Infix::Modulo is Q::Infix {}

class Q::Infix::Divisibility is Q::Infix {}

class Q::Infix::Concat is Q::Infix {}

class Q::Infix::Replicate is Q::Infix {}

class Q::Infix::ArrayReplicate is Q::Infix {}

class Q::Infix::Cons is Q::Infix {}

class Q::Infix::Assignment is Q::Infix {
    method eval($runtime) {
        my $value = $.rhs.eval($runtime);
        $.lhs.put-value($value, $runtime);
        return $value;
    }
}

class Q::Infix::Eq is Q::Infix {}

class Q::Infix::Ne is Q::Infix {}

class Q::Infix::Gt is Q::Infix {}

class Q::Infix::Lt is Q::Infix {}

class Q::Infix::Ge is Q::Infix {}

class Q::Infix::Le is Q::Infix {}

class Q::Infix::Or is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return $l.truthy
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

class Q::Infix::DefinedOr is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return $l !~~ Val::NoneType
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

class Q::Infix::And is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return !$l.truthy
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

class Q::Infix::TypeMatch is Q::Infix {}

class Q::Infix::TypeNonMatch is Q::Infix {}

class Q::Postfix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }

    method eval($runtime) {
        my $e = $.operand.eval($runtime);
        my $c = $.identifier.eval($runtime);
        return $runtime.call($c, [$e]);
    }
}

class Q::Postfix::Index is Q::Postfix {
    has $.index;

    method attribute-order { <identifier operand index> }

    method eval($runtime) {
        given $.operand.eval($runtime) {
            when Val::Array {
                my $index = $.index.eval($runtime);
                die X::Subscript::NonInteger.new
                    if $index !~~ Val::Int;
                die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                    if $index.value >= .elements;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.value < 0;
                return .elements[$index.value];
            }
            when Val::Object | Val::Block | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                return $runtime.property($_, $propname);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Val::Array));
        }
    }

    method put-value($value, $runtime) {
        given $.operand.eval($runtime) {
            when Val::Array {
                my $index = $.index.eval($runtime);
                die X::Subscript::NonInteger.new
                    if $index !~~ Val::Int;
                die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                    if $index.value >= .elements;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.value < 0;
                .elements[$index.value] = $value;
            }
            when Val::Object | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                $runtime.put-property($_, $propname, $value);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Val::Array));
        }
    }
}

class Q::Postfix::Call is Q::Postfix {
    has $.argumentlist;

    method attribute-order { <identifier operand argumentlist> }

    method eval($runtime) {
        my $c = $.operand.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Block;
        my @arguments = $.argumentlist.arguments.elements.map(*.eval($runtime));
        return $runtime.call($c, @arguments);
    }
}

class Q::Postfix::Property is Q::Postfix {
    has $.property;

    method attribute-order { <identifier operand property> }

    method eval($runtime) {
        my $obj = $.operand.eval($runtime);
        my $propname = $.property.name.value;
        $runtime.property($obj, $propname);
    }

    method put-value($value, $runtime) {
        given $.operand.eval($runtime) {
            when Val::Object | Q {
                my $propname = $.property.name.value;
                $runtime.put-property($_, $propname, $value);
            }
            die "We don't handle this case yet"; # XXX: think more about this case
        }
    }
}

class Q::Unquote does Q {
    has $.expr;

    method eval($runtime) {
        die "Should never hit an unquote at runtime"; # XXX: turn into X::
    }
}

class Q::Unquote::Prefix is Q::Unquote {
    has $.operand;
}

class Q::Unquote::Infix is Q::Unquote {
    has $.lhs;
    has $.rhs;
}

class Q::Term::Quasi does Q::Term {
    has $.qtype;
    has $.contents;

    method attribute-order { <qtype contents> }

    method eval($runtime) {
        sub interpolate($thing) {
            return $thing.new(:elements($thing.elements.map(&interpolate)))
                if $thing ~~ Val::Array;

            return $thing.new(:properties(%($thing.properties.map(.key => interpolate(.value)))))
                if $thing ~~ Val::Object;

            return $thing
                if $thing ~~ Val;

            return $thing.new(:name($thing.name), :frame($runtime.current-frame))
                if $thing ~~ Q::Identifier;

            if $thing ~~ Q::Unquote::Prefix {
                my $prefix = $thing.expr.eval($runtime);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($prefix), :expected(Q::Prefix))
                    unless $prefix ~~ Q::Prefix;
                return $prefix.new(:identifier($prefix.identifier), :operand($thing.operand));
            }
            elsif $thing ~~ Q::Unquote::Infix {
                my $infix = $thing.expr.eval($runtime);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($infix), :expected(Q::Infix))
                    unless $infix ~~ Q::Infix;
                return $infix.new(:identifier($infix.identifier), :lhs($thing.lhs), :rhs($thing.rhs));
            }

            if $thing ~~ Q::Unquote {
                my $ast = $thing.expr.eval($runtime);
                die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
                    unless $ast ~~ Q;
                return $ast;
            }

            my %attributes = $thing.attributes.map: -> $attr {
                aname($attr) => interpolate(avalue($attr, $thing))
            };

            $thing.new(|%attributes);
        }

        if $.qtype.value eq "Q::Unquote" && $.contents ~~ Q::Unquote {
            return $.contents;
        }
        return interpolate($.contents);
    }
}

class Q::Parameter does Q does Q::Declaration {
    has $.identifier;

    method is-assignable { True }
}

class Q::ParameterList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.parameters = Val::Array.new;
}

class Q::ArgumentList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.arguments = Val::Array.new;
}

role Q::Statement does Q {
}

class Q::Statement::My does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.expr = NONE;

    method attribute-order { <identifier expr> }

    method is-assignable { True }

    method run($runtime) {
        return
            unless $.expr !~~ Val::NoneType;
        my $value = $.expr.eval($runtime);
        $.identifier.put-value($value, $runtime);
    }
}

class Q::Statement::Constant does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.expr;

    method attribute-order { <identifier expr> }

    method run($runtime) {
        # value has already been assigned
    }
}

class Q::Statement::Expr does Q::Statement {
    has $.expr;

    method run($runtime) {
        $.expr.eval($runtime);
    }
}

class Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;
    has $.else = NONE;

    method attribute-order { <expr block else> }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if $expr.truthy {
            my $c = $.block.reify($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.elems;
            die X::ParameterMismatch.new(
                :type("If statement"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.identifier, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
        else {
            given $.else {
                when Q::Statement::If {
                    $.else.run($runtime)
                }
                when Q::Block {
                    my $c = $.else.reify($runtime);
                    $runtime.enter($c);
                    $.else.statementlist.run($runtime);
                    $runtime.leave;
                }
            }
        }
    }
}

class Q::Statement::Block does Q::Statement {
    has $.block;

    method run($runtime) {
        $runtime.enter($.block.reify($runtime));
        $.block.statementlist.run($runtime);
        $runtime.leave;
    }
}

class Q::CompUnit is Q::Statement::Block {
}

class Q::Statement::For does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        my $c = $.block.reify($runtime);
        my $count = $c.parameterlist.parameters.elements.elems;
        die X::ParameterMismatch.new(
            :type("For loop"), :paramcount($count), :argcount("0 or 1"))
            if $count > 1;

        my $array = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation("for loop"), :got($array), :expected(Val::Array))
            unless $array ~~ Val::Array;

        for $array.elements -> $arg {
            $runtime.enter($c);
            if $count == 1 {
                $runtime.declare-var($c.parameterlist.parameters.elements[0].identifier, $arg.list[0]);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
}

class Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        while (my $expr = $.expr.eval($runtime)).truthy {
            my $c = $.block.reify($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.identifier, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
}

class Q::Statement::Return does Q::Statement {
    has $.expr = NONE;

    method run($runtime) {
        my $value = $.expr ~~ Val::NoneType ?? $.expr !! $.expr.eval($runtime);
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }
}

class Q::Statement::Throw does Q::Statement {
    has $.expr = NONE;

    method run($runtime) {
        my $value = $.expr ~~ Val::NoneType
            ?? Val::Exception.new(:message(Val::Str.new(:value("Died"))))
            !! $.expr.eval($runtime);
        die X::TypeCheck.new(:got($value), :excpected(Val::Exception))
            if $value !~~ Val::Exception;

        die X::_007::RuntimeException.new(:msg($value.message.value));
    }
}

class Q::Statement::Sub does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has Q::Block $.block;

    method attribute-order { <identifier traitlist block> }

    method run($runtime) {
    }
}

class Q::Statement::Macro does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }

    method run($runtime) {
    }
}

class Q::Statement::BEGIN does Q::Statement {
    has $.block;

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
}

class Q::Statement::Class does Q::Statement does Q::Declaration {
    has $.block;

    method run($runtime) {
        # a class block does not run at runtime
    }
}

class Q::StatementList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.statements = Val::Array.new;

    method run($runtime) {
        for $.statements.elements -> $statement {
            $statement.run($runtime);
        }
    }
}

class Q::Expr::StatementListAdapter does Q::Expr {
    has $.statementlist;

    method eval($runtime) {
        $.statementlist.run($runtime);
        return NONE;
    }
}
