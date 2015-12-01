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

class X::PropertyNotFound is Exception {
    has $.propname;

    method message {
        "Property '$.propname' not found"
    }
}

role Q {
    method Str {
        sub aname($attr) { $attr.name.substr(2) }
        sub avalue($attr) { $attr.get_value(self) }

        my @attrs = self.attributes;
        if @attrs == 1 {
            return "{self.^name} { avalue(@attrs[0]).Str }";
        }
        sub keyvalue($attr) { aname($attr) ~ ": " ~ avalue($attr) }
        my $contents = @attrs.map(&keyvalue).join(",\n").indent(4);
        return "{self.^name} \{\n$contents\n\}";
    }

    method quoted-Str {
        self.Str
    }

    method attributes {
        sub aname($attr) { $attr.name.substr(2) }
        sub find($aname) { self.^attributes.first({ $aname eq aname($_) }) }

        self.can("attribute-order")
            ?? self.attribute-order.map({ find($_) })
            !! self.^attributes;
    }
}

role Q::Expr does Q {
}

role Q::Literal does Q::Expr {
}

role Q::Literal::None does Q::Literal {
    method eval($) { Val::None.new }
    method interpolate($) { self }
}

role Q::Literal::Int does Q::Literal {
    has Val::Int $.value;

    method eval($) { $.value }
    method interpolate($) { self }
}

role Q::Literal::Str does Q::Literal {
    has Val::Str $.value;

    method eval($) { $.value }
    method interpolate($) { self }
}

role Q::Identifier does Q::Expr {
    has Val::Str $.name;

    method eval($runtime) {
        return $runtime.get-var($.name.value);
    }
    method interpolate($) { self }
}

role Q::Term does Q::Expr {
}

role Q::Term::Array does Q::Term {
    has Val::Array $.elements;

    method eval($runtime) {
        Val::Array.new(:elements($.elements.elements».eval($runtime)));
    }
    method interpolate($runtime) {
        self.new(:elements(@.elements».interpolate($runtime)));
    }
}

role Q::Term::Quasi does Q::Term {
    has $.block;

    method eval($runtime) {
        return $.block.interpolate($runtime);
    }
    method interpolate($runtime) {
        self.new(:block($.block.interpolate($runtime)));
        # XXX: the fact that we keep interpolating inside of the quasi means
        # that unquotes encountered inside of this inner quasi will be
        # interpolated in the context of the outer quasi. is this correct?
        # can we come up with a case where it matters?
    }
}

role Q::Expr::Block { ... }

role Q::Term::Object does Q::Term {
    has Q::Identifier $.type;
    has $.propertylist;

    method eval($runtime) {
        if $.type.name.value eq "Object" {
            return Val::Object.new(:properties(
                $.propertylist.properties.elements.map({.key.value => .value.eval($runtime)})
            ));
        }
        elsif $.type.name.value eq "Int" | "Str" {
            return types(){$.type.name.value}.new(
                :value($.propertylist.properties.elements[0].value.eval($runtime).value)
            );
        }
        elsif $.type.name.value eq "Array" {
            return types(){$.type.name.value}.new(
                :elements($.propertylist.properties.elements[0].value.eval($runtime).elements)
            );
        }
        else {
            return types(){$.type.name.value}.new(
                |%($.propertylist.properties.elements.map({.key.value => .value.eval($runtime)}))
            );
        }
    }
}

role Q::Property does Q {
    has Val::Str $.key;
    has $.value;
}

role Q::PropertyList does Q {
    has Val::Array $.properties = Val::Array.new;
    method interpolate($runtime) {
        self.new(:properties(@.properties».interpolate($runtime)));
    }
}

role Q::Block does Q {
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
    method interpolate($runtime) {
        Q::Expr::Block.new(
            :parameterlist($.parameterlist.interpolate($runtime)),
            :statementlist($.statementlist.interpolate($runtime)),
            :outer-frame($runtime.current-frame));
        # XXX: but what about the static lexpad? we kind of lose it here, don't we?
        # what does that *mean* in practice? can we come up with an example where
        # it matters? if the static lexpad happens to contain a value which is a
        # Q node, do we continue into *it*, interpolating it, too?
    }
}

role Q::Expr::Block does Q::Block {
    has $.outer-frame;

    # attribute-order inherited and unchanged

    method eval($runtime) {
        Val::Block.new(
            :$.parameterlist,
            :$.statementlist,
            :%.static-lexpad,
            :$.outer-frame
        );
    }
}

role Q::Unquote does Q {
    has $.expr;

    method eval($runtime) {
        die "Should never hit an unquote at runtime"; # XXX: turn into X::
    }
    method interpolate($runtime) {
        my $q = $.expr.eval($runtime);
        die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
            unless $q ~~ Q;
        return $q;
    }
}

role Q::Prefix[$type] does Q::Expr {
    has $.expr;

    method type { $type }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $runtime.get-var("prefix:$type");
        return $runtime.call($c, [$e]);
    }

    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)));
    }
}

role Q::Prefix::Minus does Q::Prefix["<->"] {}

role Q::Infix[$type] does Q::Expr {
    has $.lhs;
    has $.rhs;

    method type { $type }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $runtime.get-var("infix:$type");
        return $runtime.call($c, [$l, $r]);
    }

    method interpolate($runtime) {
        self.new(:lhs($.lhs.interpolate($runtime)), :rhs($.rhs.interpolate($runtime)));
    }
}

role Q::Infix::Addition does Q::Infix["<+>"] {}

role Q::Infix::Subtraction does Q::Infix["<->"] {}

role Q::Infix::Multiplication does Q::Infix["<*>"] {}

role Q::Infix::Concat does Q::Infix["<~>"] {}

role Q::Infix::Assignment does Q::Infix["<=>"] {
    method eval($runtime) {
        die "Needs to be an identifier on the left"     # XXX: Turn this into an X::
            unless $.lhs ~~ Q::Identifier;
        my $value = $.rhs.eval($runtime);
        $runtime.put-var($.lhs.name.value, $value);
        return $value;
    }
}

role Q::Infix::Eq does Q::Infix["<==>"] {}

role Q::Postfix[$type] does Q::Expr {
    has $.expr;

    method type { $type }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $runtime.get-var("postfix:$type");
        return $runtime.call($c, [$e]);
    }
}

role Q::Postfix::Index does Q::Postfix["<[>"] {
    has $.index;

    method attribute-order { <expr index> }

    method eval($runtime) {
        given $.expr.eval($runtime) {
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
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :index($.index.interpolate($runtime)));
    }
}

role Q::Postfix::Call does Q::Postfix["<(>"] {
    has $.argumentlist;

    method attribute-order { <expr argumentlist> }

    method eval($runtime) {
        my $c = $.expr.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Block;
        my @args = $.argumentlist.arguments.elements».eval($runtime);
        return $runtime.call($c, @args);
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :argumentlist($.argumentlist.interpolate($runtime)));
    }
}

role Q::Postfix::Property does Q::Postfix["<.>"] {
    has $.ident;

    method attribute-order { <expr ident> }

    method eval($runtime) {
        my $obj = $.expr.eval($runtime);
        my $propname = $.ident.name.value;
        $runtime.property($obj, $propname);
    }

    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :ident($.ident.interpolate($runtime)));
    }
}

role Q::ParameterList does Q {
    has Val::Array $.parameters = Val::Array.new;
    method interpolate($runtime) {
        self.new(:parameters(Val::Array.new(:elements($.parameters.elements».interpolate($runtime)))));
    }
}

role Q::ArgumentList does Q {
    has Val::Array $.arguments = Val::Array.new;
    method interpolate($runtime) {
        self.new(:arguments(Val::Array.new(:elements($.arguments.elements».interpolate($runtime)))));
    }
}

role Q::Statement does Q {
}

role Q::Statement::My does Q::Statement {
    has $.ident;
    has $.expr;

    method attribute-order { <expr ident> }

    method run($runtime) {
        return
            unless $.expr !~~ Val::None;
        my $value = $.expr.eval($runtime);
        $runtime.put-var($.ident.name.value, $value);
    }
    method interpolate($runtime) {
        self.new(
            :ident($.ident.interpolate($runtime)),
            :expr($.expr ~~ Val::None ?? $.expr !! $.expr.interpolate($runtime)));
    }
}

role Q::Statement::Constant does Q::Statement {
    has $.ident;
    has $.expr;

    method attribute-order { <expr ident> }

    method run($runtime) {
        # value has already been assigned
    }
    method interpolate($runtime) {
        self.new(
            :ident($.ident.interpolate($runtime)),
            :expr($.expr ~~ Val::None ?? $.expr !! $.expr.interpolate($runtime)));   # XXX: and here
    }
}

role Q::Statement::Expr does Q::Statement {
    has $.expr;

    method run($runtime) {
        $.expr.eval($runtime);
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)));
    }
}

role Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }

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
                $runtime.declare-var($param.name.value, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :block($.block.interpolate($runtime)));
    }
}

role Q::Statement::Block does Q::Statement {
    has $.block;

    method run($runtime) {
        $runtime.enter($.block.eval($runtime));
        $.block.statementlist.run($runtime);
        $runtime.leave;
    }
    method interpolate($runtime) {
        self.new(:block($.block.interpolate($runtime)));
    }
}

role Q::CompUnit does Q::Statement::Block {
}

role Q::Statement::For does Q::Statement {
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
                    $runtime.declare-var($param.name.value, $real_arg);
                }
                $.block.statementlist.run($runtime);
                $runtime.leave;
            }
        }
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :block($.block.interpolate($runtime)));
    }
}

role Q::Statement::While does Q::Statement {
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
                $runtime.declare-var($param.name.value, $arg);
            }
            $.block.statementlist.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)), :block($.block.interpolate($runtime)));
    }
}

role Q::Statement::Return does Q::Statement {
    has $.expr;

    method run($runtime) {
        my $value = $.expr ~~ Val::None ?? $.expr !! $.expr.eval($runtime);
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }
    method interpolate($runtime) {
        self.new(:expr($.expr.interpolate($runtime)));
    }
}

role Q::Statement::Sub does Q::Statement {
    has $.ident;
    has $.block;

    method attribute-order { <ident block> }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new(:ident($.ident.interpolate($runtime)),
            :block($.block.interpolate($runtime)));
    }
}

role Q::Statement::Macro does Q::Statement {
    has $.ident;
    has $.block;

    method attribute-order { <ident block> }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new(:ident($.ident.interpolate($runtime)),
            :block($.block.interpolate($runtime)));
    }
}

role Q::Statement::BEGIN does Q::Statement {
    has $.block;

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
    method interpolate($runtime) {
        self.new(:block($.block.interpolate($runtime)));
    }
}

role Q::StatementList does Q {
    has Val::Array $.statements = Val::Array.new;

    method run($runtime) {
        for $.statements.elements -> $statement {
            $statement.run($runtime);
        }
    }
    method interpolate($runtime) {
        self.new(:statements(Val::Array.new(:elements($.statements.elements».interpolate($runtime)))));
    }
}

role Q::Trait does Q {
    has $.ident;
    has $.expr;

    method attribute-order { <ident expr> }

    method interpolate($runtime) {
        self.new(:ident($.ident.interpolate($runtime)), :expr($.expr.interpolate($runtime)));
    }
}

sub types() is export {
    return %(
        "None"                   => Val::None,
        "Int"                    => Val::Int,
        "Str"                    => Val::Str,
        "Array"                  => Val::Array,
        "Object"                 => Val::Object,
        "Q::Identifier"          => Q::Identifier,
        "Q::Literal::None"       => Q::Literal::None,
        "Q::Literal::Int"        => Q::Literal::Int,
        "Q::Literal::Str"        => Q::Literal::Str,
        "Q::Term::Array"         => Q::Term::Array,
        "Q::Term::Object"        => Q::Term::Object,
        "Q::Property"            => Q::Property,
        "Q::PropertyList"        => Q::PropertyList,
        "Q::Block"               => Q::Block,
        "Q::Expr::Block"         => Q::Expr::Block,
        "Q::Identifier"          => Q::Identifier,
        "Q::Unquote"             => Q::Unquote,
        "Q::Prefix::Minus"       => Q::Prefix::Minus,
        "Q::Infix::Addition"     => Q::Infix::Addition,
        "Q::Infix::Concat"       => Q::Infix::Concat,
        "Q::Infix::Assignment"   => Q::Infix::Assignment,
        "Q::Infix::Eq"           => Q::Infix::Eq,
        "Q::Postfix::Index"      => Q::Postfix::Index,
        "Q::Postfix::Call"       => Q::Postfix::Call,
        "Q::Postfix::Property"   => Q::Postfix::Property,
        "Q::ParameterList"       => Q::ParameterList,
        "Q::ArgumentList"        => Q::ArgumentList,
        "Q::Statement::My"       => Q::Statement::My,
        "Q::Statement::Constant" => Q::Statement::Constant,
        "Q::Statement::Expr"     => Q::Statement::Expr,
        "Q::Statement::If"       => Q::Statement::If,
        "Q::Statement::Block"    => Q::Statement::Block,
        "Q::CompUnit"            => Q::CompUnit,
        "Q::Statement::For"      => Q::Statement::For,
        "Q::Statement::While"    => Q::Statement::While,
        "Q::Statement::Return"   => Q::Statement::Return,
        "Q::Statement::Sub"      => Q::Statement::Sub,
        "Q::Statement::Macro"    => Q::Statement::Macro,
        "Q::Statement::BEGIN"    => Q::Statement::BEGIN,
        "Q::StatementList"       => Q::StatementList,
        "Q::Trait"               => Q::Trait,
        "Q::Term::Quasi"         => Q::Term::Quasi,
    );
}
