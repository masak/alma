use _007::Val;

class X::Control::Return is Exception {
    has $.frame;
    has $.value;
}

class X::Subscript::TooLarge is Exception {
}

class X::Subscript::NonInteger is Exception {
}

role Q {
}

role Q::Literal does Q {
}

role Q::Literal::None does Q::Literal {
    method new() { self.bless }
    method Str { "None" }

    method eval($) { Val::None.new }
    method interpolate($) { self }
}

role Q::Literal::Int does Q::Literal {
    has $.value;
    method new(Int $value) { self.bless(:$value) }
    method Str { "Int[$.value]" }

    method eval($) { Val::Int.new(:$.value) }
    method interpolate($) { self }
}

role Q::Literal::Str does Q::Literal {
    has $.value;
    method new(Str $value) { self.bless(:$value) }
    method Str { qq[Str["$.value"]] }

    method eval($) {
        my $value = $.value.subst(q[\"], q["], :g).subst(q[\\\\], q[\\], :g);
        Val::Str.new(:$value);
    }
    method interpolate($) { self }
}

sub children(*@c) {
    "\n" ~ @c.join("\n").indent(2);
}

role Q::Literal::Array does Q::Literal {
    has @.elements;
    method new(*@elements) {
        self.bless(:@elements)
    }
    method Str { "Array" ~ children(@.elements) }

    method eval($runtime) {
        Val::Array.new(:elements(@.elements>>.eval($runtime)));
    }
    method interpolate($runtime) {
        self.new(@.elements».interpolate($runtime));
    }
}

role Q::Block does Q {
    has $.parameters;
    has $.statements;
    method new($parameters, $statements) { self.bless(:$parameters, :$statements) }
    method Str { "Block" ~ children($.parameters, $.statements) }

    method eval($runtime) {
        my $outer-frame = $runtime.current-frame;
        Val::Block.new(:$.parameters, :$.statements, :$outer-frame);
    }
    method interpolate($runtime) {
        self.new(
            $.parameters.interpolate($runtime),
            $.statements.interpolate($runtime));
    }
}

role Q::Identifier does Q {
    has $.name;
    method new(Str $name) { self.bless(:$name) }
    method Str { "Identifier[$.name]" }

    method eval($runtime) {
        return $runtime.get-var($.name);
    }
    method interpolate($) { self }
}

role Q::Unquote does Q {
    has $.expr;
    method new($expr) { self.bless(:$expr) }
    method Str { "Unquote" ~ children($.expr) }

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

role Q::Prefix does Q {
    has $.expr;
    has $.type = "";
    method new($expr) { self.bless(:$expr) }
    method Str { "Prefix" ~ self.type ~ children($.expr) }

    method eval($runtime) { ... }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime));
    }
}

role Q::Prefix::Minus does Q::Prefix {
    method type { "[-]" }
    method eval($runtime) {
        my $expr = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation<->, :got($expr), :expected(Val::Int))
            unless $expr ~~ Val::Int;
        return Val::Int.new(:value(-$expr.value));
    }
}

role Q::Prefix::Custom[$type] does Q::Prefix {
    method type { "[$type]" }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $runtime.get-var("prefix:<$type>");
        return $runtime.call($c, [$e]);
    }
}

role Q::Infix does Q {
    has $.lhs;
    has $.rhs;
    has $.type = "";
    method new($lhs, $rhs) { self.bless(:$lhs, :$rhs) }
    method Str { "Infix" ~ self.type ~ children($.lhs, $.rhs) }

    method eval($runtime) { ... }
    method interpolate($runtime) {
        self.new($.lhs.interpolate($runtime), $.rhs.interpolate($runtime));
    }
}

role Q::Infix::Addition does Q::Infix {
    method type { "[+]" }
    method eval($runtime) {
        my $lhs = $.lhs.eval($runtime);
        die X::TypeCheck.new(:operation<+>, :got($lhs), :expected(Val::Int))
            unless $lhs ~~ Val::Int;
        my $rhs = $.rhs.eval($runtime);
        die X::TypeCheck.new(:operation<+>, :got($rhs), :expected(Val::Int))
            unless $rhs ~~ Val::Int;
        return Val::Int.new(:value(
            $lhs.value + $rhs.value
        ));
    }
}

role Q::Infix::Concat does Q::Infix {
    method type { "[~]" }
    method eval($runtime) {
        my $lhs = $.lhs.eval($runtime);
        die X::TypeCheck.new(:operation<~>, :got($lhs), :expected(Val::Str))
            unless $lhs ~~ Val::Str;
        my $rhs = $.rhs.eval($runtime);
        die X::TypeCheck.new(:operation<~>, :got($rhs), :expected(Val::Str))
            unless $rhs ~~ Val::Str;
        return Val::Str.new(:value(
            $lhs.value ~ $rhs.value
        ));
    }
}

role Q::Infix::Assignment does Q::Infix {
    method type { "[=]" }
    method eval($runtime) {
        die "Needs to be an identifier on the left"     # XXX: Turn this into an X::
            unless $.lhs ~~ Q::Identifier;
        my $value = $.rhs.eval($runtime);
        $runtime.put-var($.lhs.name, $value);
        return $value;
    }
}

role Q::Infix::Eq does Q::Infix {
    method type { "[==]" }
    method eval($runtime) {
        multi equal-value(Val $, Val $) { False }
        multi equal-value(Val::None, Val::None) { True }
        multi equal-value(Val::Int $r, Val::Int $l) { $r.value == $l.value }
        multi equal-value(Val::Str $r, Val::Str $l) { $r.value eq $l.value }
        multi equal-value(Val::Array $r, Val::Array $l) {
            return False unless $r.elements == $l.elements;
            for $r.elements.list Z $l.elements.list -> ($re, $le) {
                return False unless equal-value($re, $le);
            }
            return True;
        }

        my $r = $.rhs.eval($runtime);
        my $l = $.lhs.eval($runtime);
        # converting Bool->Int because the implemented language doesn't have Bool
        my $equal = +equal-value($r, $l);
        return Val::Int.new(:value($equal));
    }
}

role Q::Infix::Custom[$type] does Q::Infix {
    method type { "[$type]" }

    method eval($runtime) {
        my $l = $.lhs.eval($runtime);
        my $r = $.rhs.eval($runtime);
        my $c = $runtime.get-var("infix:<$type>");
        return $runtime.call($c, [$l, $r]);
    }
}

role Q::Postfix does Q {
    has $.expr;
    has $.type = "";
    method new($expr) { self.bless(:$expr) }
    method Str { "Postfix" ~ self.type ~ children($.expr) }

    method eval($runtime) { ... }
}

role Q::Postfix::Index does Q::Postfix {
    has $.index;
    method new($expr, $index) { self.bless(:$expr, :$index) }
    method Str { "Index" ~ children($.expr, $.index) }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        die X::TypeCheck.new(:operation<indexing>, :got($e), :expected(Val::Array))
            unless $e ~~ Val::Array;
        my $index = $.index.eval($runtime);
        die X::Subscript::NonInteger.new
            if $index !~~ Val::Int;
        die X::Subscript::TooLarge.new
            if $index.value >= $e.elements;
        die X::Subscript::Negative.new(:$index, :type([]))
            if $index.value < 0;
        return $e.elements[$index.value];
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.index.interpolate($runtime));
    }
}

role Q::Postfix::Call does Q::Postfix {
    has $.arguments;
    method new($expr, $arguments) { self.bless(:$expr, :$arguments) }
    method Str { "Call" ~ children($.expr, $.arguments) }

    method eval($runtime) {
        my $c = $.expr.eval($runtime);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Block;
        my @args = $.arguments.arguments».eval($runtime);
        return $runtime.call($c, @args);
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.arguments.interpolate($runtime));
    }
}

role Q::Postfix::Custom[$type] does Q::Postfix {
    method type { "[$type]" }

    method eval($runtime) {
        my $e = $.expr.eval($runtime);
        my $c = $runtime.get-var("postfix:<$type>");
        return $runtime.call($c, [$e]);
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime));
    }
}

role Q::Parameters does Q {
    has @.parameters;
    method new(*@parameters) { self.bless(:@parameters) }
    method Str { "Parameters" ~ children(@.parameters) }
    method interpolate($runtime) {
        self.new(@.parameters».interpolate($runtime));
    }
}

role Q::Arguments does Q {
    has @.arguments;
    method new(*@arguments) { self.bless(:@arguments) }
    method Str { "Arguments" ~ children(@.arguments) }
    method interpolate($runtime) {
        self.new(@.arguments».interpolate($runtime));
    }
}

role Q::Statement does Q {
}

role Q::Statement::My does Q::Statement {
    has $.ident;
    has $.assignment;
    method new($ident, $assignment = Empty) { self.bless(:$ident, :$assignment) }
    method Str { "My" ~ children($.ident, |$.assignment) }

    method run($runtime) {
        return
            unless $.assignment;
        $.assignment.eval($runtime);
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.assignment === Empty ?? Empty !! $.assignment.interpolate($runtime));
    }
}

role Q::Statement::Constant does Q::Statement {
    has $.ident;
    has $.assignment;
    method new($ident, $assignment = Empty) { self.bless(:$ident, :$assignment) }
    method Str { "Constant" ~ children($.ident, |$.assignment) }    # XXX: remove | once we guarantee it

    method run($runtime) {
        # value has already been assigned
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.assignment === Empty ?? Empty !! $.assignment.interpolate($runtime));   # XXX: and here
    }
}

role Q::Statement::Expr does Q::Statement {
    has $.expr;
    method new($expr) { self.bless(:$expr) }
    method Str { "Expr" ~ children($.expr) }

    method run($runtime) {
        $.expr.eval($runtime);
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime));
    }
}

role Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;
    method new($expr, Q::Block $block) { self.bless(:$expr, :$block) }
    method Str { "If" ~ children($.expr, $.block) }

    method run($runtime) {
        my $expr = $.expr.eval($runtime);
        if $expr.truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            die "Too many parameters in if statements"  # XXX: needs a test and a real exception
                if $c.parameters.parameters > 1;
            for $c.parameters.parameters Z $expr -> ($param, $arg) {
                $runtime.declare-var($param.name);
                $runtime.put-var($param.name, $arg);
            }
            $.block.statements.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.block.interpolate($runtime));
    }
}

role Q::Statement::Block does Q::Statement {
    has $.block;
    method new(Q::Block $block) { self.bless(:$block) }
    method Str { "Statement block" ~ children($.block) }

    method run($runtime) {
        $runtime.enter($.block.eval($runtime));
        $.block.statements.run($runtime);
        $runtime.leave;
    }
    method interpolate($runtime) {
        self.new($.block.interpolate($runtime));
    }
}

role Q::CompUnit does Q::Statement::Block {
    method Str { "CompUnit" ~ children($.block) }
}

role Q::Statement::For does Q::Statement {
    has $.expr;
    has $.block;
    method new($expr, Q::Block $block) { self.bless(:$expr, :$block) }
    method Str { "For" ~  children($.expr, $.block)}

    method run($runtime) {
        multi elements(Q::Literal::Array $array) {
            return $array.elements>>.value;
        }

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
        my $count = $c.parameters.parameters.elems;

        if $count == 0 {
            for ^elements($.expr).elems {
                $runtime.enter($c);
                $.block.statements.run($runtime);
                $runtime.leave;
            }
        }
        else {
            for split_elements(elements($.expr), $count) -> $arg {
                $runtime.enter($c);
                for $c.parameters.parameters Z $arg.list -> ($param, $real_arg) {
                    $runtime.declare-var($param.name);
                    $runtime.put-var($param.name, $real_arg);
                }
                $.block.statements.run($runtime);
                $runtime.leave;
            }
        }
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.block.interpolate($runtime));
    }
}

role Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;
    method new($expr, Q::Block $block) { self.bless(:$expr, :$block) }
    method Str { "While" ~ children($.expr, $.block) }

    method run($runtime) {
        while $.expr.eval($runtime).truthy {
            my $c = $.block.eval($runtime);
            $runtime.enter($c);
            $.block.statements.run($runtime);
            $runtime.leave;
        }
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime), $.block.interpolate($runtime));
    }
}

role Q::Statement::Return does Q::Statement {
    has $.expr;
    sub NONE { role { method eval($) { Val::None.new }; method Str { "(no return value)" } } }
    method new($expr = NONE) { self.bless(:$expr) }
    method Str { "Return" ~ children($.expr) }

    method run($runtime) {
        my $frame = $runtime.get-var("--RETURN-TO--");
        die X::Control::Return.new(:value($.expr.eval($runtime)), :$frame);
    }
    method interpolate($runtime) {
        self.new($.expr.interpolate($runtime));
    }
}

role Q::Statement::Sub does Q::Statement {
    has $.ident;
    has $.parameters;
    has $.statements;

    method new($ident, $parameters, $statements) {
        self.bless(:$ident, :$parameters, :$statements);
    }

    method Str { "Sub[{$.ident.name}]" ~ children($.parameters, $.statements) }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.parameters.interpolate($runtime),
            $.statements.interpolate($runtime));
    }
}

role Q::Statement::Macro does Q::Statement {
    has $.ident;
    has $.parameters;
    has $.statements;

    method new($ident, $parameters, $statements) {
        self.bless(:$ident, :$parameters, :$statements);
    }

    method Str { "Macro[{$.ident.name}]" ~ children($.parameters, $.statements) }

    method run($runtime) {
    }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime),
            $.parameters.interpolate($runtime),
            $.statements.interpolate($runtime));
    }
}

role Q::Statement::BEGIN does Q::Statement {
    has $.block;
    method new(Q::Block $block) { self.bless(:$block) }
    method Str { "BEGIN block" ~ children($.block) }

    method run($runtime) {
        # a BEGIN block does not run at runtime
    }
    method interpolate($runtime) {
        self.new($.block.interpolate($runtime));
    }
}

role Q::Statements does Q {
    has @.statements;
    has %.static-lexpad is rw;
    method new(*@statements) { self.bless(:@statements) }
    method Str { "Statements" ~ children(@.statements) }

    method run($runtime) {
        for @.statements -> $statement {
            $statement.run($runtime);
        }
    }
    method interpolate($runtime) {
        self.new(@.statements».interpolate($runtime));
        # XXX: but what about the static lexpad? we kind of lose it here, don't we?
        # what does that *mean* in practice? can we come up with an example where
        # it matters? if the static lexpad happens to contain a value which is a
        # Q node, do we continue into *it*, interpolating it, too?
    }
}

role Q::Trait does Q {
    has $.ident;
    has $.expr;

    method new($ident, $expr) {
        self.bless(:$ident, :$expr);
    }

    method Str { "Trait[{$.ident.name}]" ~ children($.expr) }
    method interpolate($runtime) {
        self.new($.ident.interpolate($runtime), $.expr.interpolate($runtime));
    }
}

role Q::Quasi does Q {
    has $.statements;
    method new($statements) { self.bless(:$statements) }
    method Str { "Quasi" ~ children($.statements) }

    method eval($runtime) {
        my $statements = $.statements.interpolate($runtime);
        return Q::Block.new(Q::Parameters.new, $statements);
    }
    method interpolate($runtime) {
        self.new($.statements.interpolate($runtime));
        # XXX: the fact that we keep interpolating inside of the quasi means
        # that unquotes encountered inside of this inner quasi will be
        # interpolated in the context of the outer quasi. is this correct?
        # can we come up with a case where it matters?
    }
}

