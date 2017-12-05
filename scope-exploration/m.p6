#! /usr/bin/env perl6

# The literal zero is the only literal. Its value is zero.

class E::LiteralZero {
    method new() { self.bless() }
}

# The prefix:<succ> operator has the value of its operand,
# plus one.

class E::Succ {
    has $.operand;
    method new($operand) { self.bless(:$operand) }
}

# An identifier is a name identifying a value. The value is in
# a pad somewhere. Finding the right pad is called *lookup*.
# Lookup cannot happen without a *context*, somewhere inside
# a program.

class E::Identifier {
    has Str $.name;
    method new(Str $name) { self.bless(:$name) }
}

# A call is the application of one expression (which needs
# to evaluate to a Fn) to another (its argument).

class E::Call {
    has $.fn;
    has $.argument;
    method new($fn, $argument) { self.bless(:$fn, :$argument) }
}

# An expr statement evaluates an expression, consisting of a
# number of `succ` prefixes followed by either a literal 0 or
# an identifier or a call.
# Its value is the value of the expression.

class S::Expr {
    has $.expr;
    method new($expr) { self.bless(:$expr) }
}

# A My statement declares a new identifier in its surrounding
# block. Such a declaration does not in itself have a value.

class S::My {
    has Str $.name;
    has $.expr;
    method new(Str $name, $expr) { self.bless(:$name, :$expr) }
}

# A block contains one or more statements. The value of the whole
# block is the value of the last statement in that block.

class S::Block {
    has @.statements;
    method new(*@statements) { self.bless(:@statements) }
}

# A sub declaration consists of the sub's name, the name of exactly one
# parameter (à la lambda calculus), and a block. The value of the sub
# declaration itself is Nil. The value of running the sub is the value
# of running its block.

class S::Sub {
    has Str $.name;
    has Str $.parameter;
    has S::Block $.block;
    method new(Str $name, Str $parameter, S::Block $block) {
        self.bless(:$name, :$parameter, :$block);
    }
}

# A (lexical) pad is the thing that binds variable names
# to their values.

class Pad {
    has %!bindings;
    method declare($name) { self.set($name, "<undeclared>") }
    method is-declared($name) { %!bindings{$name} :exists }
    method get($name) { %!bindings{$name} }
    method set($name, $value) { %!bindings{$name} = $value }
}

# A Fn value is what's generated form a sub declaration. It's
# the thing a reference to a function resolves to in order to
# call it or pass it.

class Fn {
    has Str $.parameter;
    has S::Block $.block;
    method new($parameter, $block) { self.bless(:$parameter, :$block) }
}

# The runtime is what can execute a program. The process itself
# is associated with some mutable state: the pads of the blocks
# the runtime is currently in.

sub run(S::Block $program) {
    my @pad-chain;

    sub is-declared(Str $name) { -> $pad { $pad.is-declared($name) } }
    sub lookup(Str $name) {
        my $pad = @pad-chain.first(is-declared($name))
            or die X::Undeclared.new(:symbol($name));
        $pad.get($name);
    }
    sub set(Str $name, $value) { @pad-chain[0].set($name, $value) }

    multi evaluate-expr($e) { die "Don't know how to evaluate ", $e.^name }
    multi evaluate-expr(E::LiteralZero $e) { 0 }
    multi evaluate-expr(E::Succ $e) { evaluate-expr($e.operand) + 1 }
    multi evaluate-expr(E::Identifier $e) { lookup($e.name) }
    multi evaluate-expr(E::Call $e) {
        my $fn = evaluate-expr($e.fn);
        my $arg = evaluate-expr($e.argument);
        run-block($fn.block, $fn.parameter, $arg);
    }

    multi run-statement($s) { die "Don't know how to run ", $s.^name }
    multi run-statement(S::My $s) { set($s.name, evaluate-expr($s.expr)) }
    multi run-statement(S::Expr $s) { evaluate-expr($s.expr) }
    multi run-statement(S::Block $s) { run-block($s) }
    multi run-statement(S::Sub $s) { set($s.name, Fn.new($s.parameter, $s.block)) }

    sub run-block(S::Block $block, Str $parameter?, $parameter-value?) {
        @pad-chain.unshift(Pad.new);
        if $parameter {
            set($parameter, $parameter-value);
        }
        my $last-value;
        for $block.statements -> $s {
            $last-value = run-statement($s);
        }
        @pad-chain.shift;
        $last-value;
    }

    run-block($program);
}

# Now we establish our expectations.
use Test;

#   x;
{
    my $program = S::Block.new(
        S::Expr.new(E::Identifier.new("x")));
    throws-like -> { run($program) }, X::Undeclared, "a variable needs to be declared to be used";
}

#   my x = 0;
#   x;
{
    my $program = S::Block.new(
        S::My.new("x", E::LiteralZero.new()),
        S::Expr.new(E::Identifier.new("x")));
    my $output = run($program);
    is $output, 0, "a program outputs the value of its last statement";
}

# Let's explore nested blocks and lookup.

#   my x = 0;
#   {
#       my x = succ 0;
#   }
#   x;
{
    my $program = S::Block.new(
        S::My.new("x", E::LiteralZero.new()),
        S::Block.new(
            S::My.new("x", E::Succ.new(E::LiteralZero.new()))),
        S::Expr.new(E::Identifier.new("x")));
    my $output = run($program);
    is $output, 0, "setting a shadowing variable shouldn't affect the shadowed variable";
}

#   sub foo(x) {
#       succ x;
#   }
#   foo(0);
{
    my $program = S::Block.new(
        S::Sub.new("foo", "x", S::Block.new(
            S::Expr.new(E::Succ.new(E::Identifier.new("x"))))),
        S::Expr.new(E::Call.new(E::Identifier.new("foo"), E::LiteralZero.new())));
    my $output = run($program);
    is $output, 1, "calling a sub works";
}

#   sub foo(x) {
#       succ x;
#   }
#   foo(0);
#   x;
{
    my $program = S::Block.new(
        S::Sub.new("foo", "x", S::Block.new(
            S::Expr.new(E::Succ.new(E::Identifier.new("x"))))),
        S::Expr.new(E::Call.new(E::Identifier.new("foo"), E::LiteralZero.new())),
        S::Expr.new(E::Identifier.new("x")));
    throws-like -> { run($program) }, X::Undeclared, "a sub's parameter is only declared inside the sub";
}

done-testing;
