role Val {}
role Val::None does Val {}
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

sub children(*@c) {
    "\n" ~ @c.join("\n").indent(2)
}

role Q {
}

role Q::Literal::Int does Q {
    has $.value;
    method new(Int $value) { self.bless(:$value) }
    method Str { "Int[$.value]" }

    method eval($) { Val::Int.new(:$.value) }
}

role Q::Literal::Str does Q {
    has $.value;
    method new(Str $value) { self.bless(:$value) }
    method Str { qq[Str["$.value"]] }

    method eval($) { Val::Str.new(:$.value) }
}

role Q::Literal::Array does Q {
    has @.elements;
    method new(*@elements) {
        self.bless(:@elements)
    }
    method Str { "Array" ~ children(@.elements) }

    method eval($) { Val::Array.new(:elements(@.elements>>.eval($))) }
}

role Q::Term::Identifier does Q {
    has $.name;
    method new(Str $name) { self.bless(:$name) }
    method Str { "Identifier[$.name]" }

    method eval($runtime) {
        return $runtime.get-var($.name);
    }
}

role Q::Expr::Infix does Q {
    has $.lhs;
    has $.rhs;
    method new($lhs, $rhs) { self.bless(:$lhs, :$rhs) }
    method Str { "Infix" ~ children($.lhs, $.rhs) }

    method eval($runtime) { ... }
}

role Q::Expr::Infix::Addition does Q::Expr::Infix {
    method eval($runtime) {
        return Val::Int.new(:value(
            $.lhs.eval($runtime).value + $.rhs.eval($runtime).value
        ));
    }
}

role Q::Expr::Infix::Concat does Q::Expr::Infix {
    method eval($runtime) {
        return Val::Str.new(:value(
            $.lhs.eval($runtime).value ~ $.rhs.eval($runtime).value
        ));
    }
}

role Q::Expr::Assignment does Q {
    has $.ident;
    has $.expr;
    method new($ident, $expr) { self.bless(:$ident, :$expr) }
    method Str { "Assign" ~ children($.ident, $.expr) }

    method eval($runtime) {
        my $value = $.expr.eval($runtime);
        $runtime.put-var($.ident.name, $value);
        return $value;
    }
}

role Q::Expr::Infix::Eq does Q::Expr::Infix {
    method eval($runtime) {
        multi equal-value(Val $, Val $) { return False }
        multi equal-value(Val::Int $r, Val::Int $l) { $r.value == $l.value }
        multi equal-value(Val::Str $r, Val::Str $l) { $r.value eq $l.value }
        multi equal-value(Val::Array $r, Val::Array $l) {
            return False unless $r.elements == $l.elements;
            for $r.elements.list Z $l.elements.list -> $re, $le {
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

role Q::Expr::Call::Sub does Q {
    has $.ident;
    has @.args;
    method new($ident, *@args) { self.bless(:$ident, :@args) }
    method Str { "Call" ~ children($.ident, |@.args) }

    method eval($runtime) {
        # TODO: de-hack -- wants to be a hash of builtins somewhere
        die "Unknown sub {$.ident.name}"
            unless $.ident.name eq "say";
        my $arg = @.args[0].eval($runtime);
        $runtime.output.say($arg.Str);
        Val::None.new;
    }
}

role Q::Statement::Expr does Q {
    has $.expr;
    method new($expr) { self.bless(:$expr) }
    method Str { "Expr" ~ children($.expr) }

    method run($runtime) {
        $.expr.eval($runtime);
    }
}

role Q::Statement::VarDecl does Q {
    has $.ident;
    has $.assignment;
    method new($ident, $assignment = Nil) { self.bless(:$ident, :$assignment) }
    method Str { "VarDecl" ~ children($.ident, |$.assignment) }

    method run($runtime) {
        # TODO: should have an if statement here, but need a test case for it
        $.assignment.eval($runtime);
    }
}

role Q::CompUnit does Q {
    has @.statements;
    method new(*@statements) { self.bless(:@statements) }
    method Str { "CompUnit" ~ children(@.statements) }

    method run($runtime) {
        for @.statements -> $statement {
            $statement.run($runtime);
        }
    }
}

role Runtime {
    has $.output;
    has %!pad;

    method run($compunit) {
        $compunit.run(self);
    }

    method put-var($name, $value) {
        %!pad{$name} = $value;
    }

    method get-var($name) {
        return %!pad{$name};
    }
}

role _007 {
    method runtime(:$output = $*OUT) {
        Runtime.new(:$output);
    }
}
