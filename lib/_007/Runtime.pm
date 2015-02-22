use _007::Q;

role Frame {
    has $.block;
    has %.pad;
}

constant NO_OUTER = {};

role Runtime {
    has $.output;
    has @!frames;

    submethod BUILD(:$output) {
        $!output = $output;
        my $setting = Val::Block.new(
            :outer-frame(NO_OUTER));
        self.enter($setting);
        self.load-builtins;
    }

    method run(Q::Statements $statements) {
        my $compunit = Val::Block.new(
            :$statements,
            :outer-frame(self.current-frame));
        self.enter($compunit);

        $statements.run(self);
        self.leave;
        CATCH {
            when X::Control::Return {
                die X::ControlFlow::Return.new;
            }
        }
    }

    method enter($block) {
        my $frame = Frame.new(:$block);
        @!frames.push($frame);
        for $block.statements.statements -> $statement {
            $statement.declare(self);
        }
        for $block.statements.static-lexpad.kv -> $name, $value {
            self.put-var($name, $value)
                unless $value ~~ Val::None; # XXX: this is almost certainly wrong
                                            # but I seemed to need it or subroutines
                                            # would be overwritten by None
        }
    }

    method leave {
        @!frames.pop;
    }

    method unroll-to($frame) {
        until self.current-frame === $frame {
            self.leave;
        }
        return;
    }

    method current-frame {
        @!frames[*-1];
    }

    method !find($symbol) {
        my $frame = self.current-frame;
        loop {
            return $frame.pad
                if $frame.pad{$symbol} :exists;
            $frame = $frame.block.outer-frame;
            last if $frame === NO_OUTER;
        }
        die X::Undeclared.new(:$symbol);
    }

    method put-var($name, $value) {
        my %pad := self!find($name);
        %pad{$name} = $value;
    }

    method get-var($name) {
        my %pad := self!find($name);
        return %pad{$name};
    }

    method declare-var($name) {
        self.current-frame.pad{$name} = Val::None.new;
    }

    method declared($name) {
        try self!find($name) && return True;
        return False;
    }

    method declared-locally($name) {
        my $frame = self.current-frame;
        return True
            if $frame.pad{$name} :exists;
    }

    method register-subhandler {
        self.declare-var("--RETURN-TO--");
        self.put-var("--RETURN-TO--", $.current-frame);
    }

    method load-builtins {
        my %builtins =
            say      => -> $arg { self.output.say(~$arg) },
            type     => sub ($arg) { return 'Sub' if $arg ~~ Val::Sub; $arg.^name.substr('Val::'.chars) },
            abs      => -> $arg { Val::Int.new(:value($arg.value.abs)) },
            min      => -> $a, $b { Val::Int.new(:value(min($a.value, $b.value))) },
            max      => -> $a, $b { Val::Int.new(:value(max($a.value, $b.value))) },
            chr      => -> $arg { Val::Str.new(:value($arg.value.chr)) },
            ord      => -> $arg { Val::Int.new(:value($arg.value.ord)) },
            int      => sub ($arg) { return Val::Int.new(:value($arg.value.Int)) if $arg.value ~~ /^ '-'? \d+ $/; return $arg },
            str      => -> $arg { Val::Str.new(:value($arg.value.Str)) },
            chars    => -> $arg { Val::Int.new(:value($arg.value.Str.chars)) },
            uc       => -> $arg { Val::Str.new(:value($arg.value.uc)) },
            lc       => -> $arg { Val::Str.new(:value($arg.value.lc)) },
            trim     => -> $arg { Val::Str.new(:value($arg.value.trim)) },
            elems    => -> $arg { Val::Int.new(:value($arg.elements.elems)) },
            reversed => -> $arg { Val::Array.new(:elements($arg.elements.reverse)) },
            sorted   => -> $arg { Val::Array.new(:elements($arg.elements.sort)) },
            join     => -> $a, $sep { Val::Str.new(:value($a.elements.join($sep.value.Str))) },
            split    => -> $s, $sep { Val::Array.new(:elements($s.value.split($sep.value))) },
            index    => -> $s, $substr { Val::Int.new(:value($s.value.index($substr.value) // -1)) },
            substr   => sub ($s, $pos, $chars?) { Val::Str.new(:value($s.value.substr($pos.value, $chars.defined ?? $chars.value !! $s.value.chars))) },
            charat   => -> $s, $pos { Val::Str.new(:value($s.value.comb[$pos.value] // die X::Subscript::TooLarge.new)) },
            grep     => -> $fn, $a {
                my $array = Val::Array.new;
                for $a.elements {
                    $array.elements.push($_) if truthy(self.call($fn, [$_]));
                }
                $array;
            },
            map      => -> $fn, $a {
                my $array = Val::Array.new;
                for $a.elements {
                    $array.elements.push(self.call($fn, [$_]));
                }
                $array;
            },
            'Q::Postfix::Call' => -> $expr, $arguments { Q::Postfix::Call.new($expr, $arguments) },
            'Q::Literal::Str' => -> $str { Q::Literal::Str.new($str.value) },
            'Q::Identifier' => -> $name { Q::Identifier.new($name.value) },
            'Q::Arguments' => -> $arguments { Q::Arguments.new($arguments.elements) },
            'infix:<+>' => -> $l, $r { #`[not implemented here] },
        ;

        for %builtins.kv -> $name, $sub {
            self.declare-var($name);
            self.put-var($name, Val::Sub::Builtin.new($sub));
        }
    }

    method sigbind($type, $c, @args) {
        die "$type with {$c.parameters.parameters.elems} parameters "       # XXX: make this into an X::
            ~ "called with {@args.elems} arguments"
            unless $c.parameters.parameters == @args;
        self.enter($c);
        for $c.parameters.parameters Z @args -> ($param, $arg) {
            my $name = $param.name;
            self.declare-var($name);
            self.put-var($name, $arg);
        }
    }

    multi method call(Val::Block $c, @args) {
        self.sigbind("Block", $c, @args);
        $c.statements.run(self);
        self.leave;
        return Val::None.new;
    }

    multi method call(Val::Sub $c, @args) {
        self.sigbind("Sub", $c, @args);
        self.register-subhandler;
        my $frame = self.current-frame;
        $c.statements.run(self);
        self.leave;
        CATCH {
            when X::Control::Return {
                die $_   # keep unrolling the interpreter's stack until we're there
                    unless .frame === $frame;
                self.unroll-to($frame);
                self.leave;
                return .value;
            }
        }
        return Val::None.new;
    }

    multi method call(Val::Sub::Builtin $c, @args) {
        my $result = $c.code.(|@args);
        return $result if $result;
        return Val::None.new;
    }
}
