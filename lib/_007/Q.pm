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

# RAKUDO: rename to X::Property::NotFound once [RT #126827] has been fixed
class X::PropertyNotFound is Exception {
    has $.propname;

    method message {
        "Property '$.propname' not found"
    }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

sub aname($attr) { $attr.name.substr(2) }
sub avalue($attr, $obj) { $attr.get_value($obj) }

role Q {
    method Str {
        my @attrs = self.attributes;
        if @attrs == 1 {
            return "{self.^name} { avalue(@attrs[0], self).quoted-Str }";
        }
        sub keyvalue($attr) { aname($attr) ~ ": " ~ avalue($attr, self).quoted-Str }
        my $contents = @attrs.map(&keyvalue).join(",\n").indent(4);
        return "{self.^name} \{\n$contents\n\}";
    }

    method quoted-Str {
        self.Str
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
    method eval($) { Val::None.new }
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
    has $.frame = Val::None.new;

    method attribute-order { <name> }

    method eval($runtime) {
        return $runtime.get-var(
            $.name.value,
            $.frame ~~ Val::None ?? $runtime.current-frame !! $.frame
        );
    }
}

class Q::Term::Array does Q::Term {
    has Val::Array $.elements;

    method eval($runtime) {
        Val::Array.new(:elements($.elements.elements».eval($runtime)));
    }
}

class Q::Term::Object does Q::Term {
    has Q::Identifier $.type;
    has $.propertylist;

    method eval($runtime) {
        return $runtime.get-var($.type.name.value).create(
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

    method interpolate($runtime) {
        self.new(:traits(Val::Array.new(:elements($.traits.elements».interpolate($runtime)))));
    }
}

class Q::Term::Sub does Q::Term does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }

    method eval($runtime) {
        my $name = $.identifier ~~ Val::None
            ?? "(anon)"
            !! $.identifier.name.value;
        return Val::Sub.new(
            :$name,
            :parameterlist($.block.parameterlist),
            :statementlist($.block.statementlist),
            :outer-frame($runtime.current-frame),
        );
    }
}

class Q::Block does Q {
    has $.parameterlist;
    has $.statementlist;
    has %.static-lexpad;

    method attribute-order { <parameterlist statementlist> }

    method eval($runtime) {
        my $outer-frame = $runtime.current-frame;
        Val::Block.new(
            :$.parameterlist,
            :$.statementlist,
            :%.static-lexpad,
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

class Q::Infix::Concat is Q::Infix {}

class Q::Infix::Replicate is Q::Infix {}

class Q::Infix::ArrayReplicate is Q::Infix {}

class Q::Infix::Cons is Q::Infix {}

class Q::Infix::Assignment is Q::Infix {
    method eval($runtime) {
        die "Needs to be an identifier on the left"     # XXX: Turn this into an X::
            unless $.lhs ~~ Q::Identifier;
        my $value = $.rhs.eval($runtime);
        $runtime.put-var($.lhs.name.value, $value);
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

class Q::Infix::And is Q::Infix {
    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        return !$l.truthy
            ?? $l
            !! $.rhs.eval($runtime);
    }
}

class Q::Infix::TypeEq is Q::Infix {}

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
            when Val::Object | Q {
                my $property = $.index.eval($runtime);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                return $runtime.property($_, $propname);
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
        my @arguments = $.argumentlist.arguments.elements».eval($runtime);
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
    has $.contents;

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

        if $.contents ~~ Q::Unquote {   # special exception: `quasi @ Q::Unquote`
            return $.contents;
        }
        return interpolate($.contents);
    }
}

class Q::ParameterList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.parameters = Val::Array.new;
}

class Q::Parameter does Q does Q::Declaration {
    has $.identifier;

    method is-assignable { True }
}

class Q::ArgumentList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.arguments = Val::Array.new;
}

role Q::Statement does Q {
}

class Q::Statement::My does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.expr = Val::None.new;

    method attribute-order { <identifier expr> }

    method is-assignable { True }

    method run($runtime) {
        return
            unless $.expr !~~ Val::None;
        my $value = $.expr.eval($runtime);
        $runtime.put-var($.identifier.name.value, $value);
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
    has $.else = Val::None.new;

    method attribute-order { <expr block else> }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if $expr.truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.elems;
            die X::ParameterMismatch.new(
                :type("If statement"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.identifier.name.value, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
        else {
            given $.else {
                when Val::None { }
                when Q::Statement::If {
                    $.else.run($runtime)
                }
                when Q::Block {
                    my $c = $.else.eval($runtime);
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
        $runtime.enter($.block.eval($runtime));
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
        multi split_elements(@array, 1) { return @array }
        multi split_elements(@array, Int $n) {
            my $list = @array.list;
            my @split;

            while True {
                my @new = $list.splice(0, $n);
                last unless @new;
                @split.push: @new.item;
            }

            @split;
        }

        my $c = $.block.eval($runtime);
        my $count = $c.parameterlist.parameters.elements.elems;

        my $array = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation("for loop"), :got($array), :expected(Val::Array))
            unless $array ~~ Val::Array;

        if $count == 0 {
            for $array.elements {
                $runtime.enter($c);
                $.block.statementlist.run($runtime);
                $runtime.leave;
            }
        }
        else {
            for split_elements($array.elements, $count) -> $arg {
                $runtime.enter($c);
                for @($c.parameterlist.parameters.elements) Z $arg.list -> ($param, $real_arg) {
                    $runtime.declare-var($param.identifier.name.value, $real_arg);
                }
                $.block.statementlist.run($runtime);
                $runtime.leave;
            }
        }
    }
}

class Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

    method run($runtime) {
        while (my $expr = $.expr.eval($runtime)).truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            my $paramcount = $c.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            for @($c.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.identifier.name.value, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
}

class Q::Statement::Return does Q::Statement {
    has $.expr = Val::None.new;

    method run($runtime) {
        my $value = $.expr ~~ Val::None ?? $.expr !! $.expr.eval($runtime);
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }
}

class Q::Statement::Sub does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

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

class Q::StatementList does Q {
    # RAKUDO: Can simplify this to `.=` once [RT #126975] is fixed
    has Val::Array $.statements = Val::Array.new;

    method run($runtime) {
        for $.statements.elements -> $statement {
            $statement.run($runtime);
        }
    }
}
