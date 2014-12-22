use _007::Q;

role Frame {
    has $.block;
    has %.pad;
}

constant NO_OUTER = {};

role Runtime {
    has $.output;
    has @!frames;

    method run(Q::Statements $statements) {
        my $parameters = Q::Parameters.new();
        my $setting = Val::Block.new(:$parameters, :statements(Q::Statements.new), :outer-frame(NO_OUTER));
        self.enter($setting);
        self.load-builtins;

        my $block = Val::Block.new(:$parameters, :$statements, :outer-frame(self.current-frame));
        self.enter($block);
        $statements.run(self);
        self.leave for ^2;
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

    method !find($name) {
        my $frame = self.current-frame;
        loop {
            return $frame.pad
                if $frame.pad{$name} :exists;
            $frame = $frame.block.outer-frame;
            last if $frame === NO_OUTER;
        }
        die "Cannot find variable '$name'";          # XXX: turn this into an X:: type
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

    method register-subhandler {
        self.declare-var("--RETURN-TO--");
        self.put-var("--RETURN-TO--", $.current-frame);
    }

    method load-builtins {
        # XXX: should be in a hash
        self.declare-var("say");
        self.put-var("say", Val::Sub::Builtin.new(-> $arg { self.output.say(~$arg) }));
    }

    method sigbind($type, $c, @args) {
        die "$type with {$c.parameters.parameters.elems} parameters "       # XXX: make this into an X::
            ~ "called with {@args.elems} arguments"
            unless $c.parameters.parameters == @args;
        self.enter($c);
        for $c.parameters.parameters Z @args -> $param, $arg {
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
        $c.code.(|@args);
        return Val::None.new;
    }
}
