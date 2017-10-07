use _007::Type;
use _007::Object;
use _007::Builtins;
use _007::OpScope;

constant NO_OUTER = wrap({});
constant RETURN_TO = create(TYPE<Q::Identifier>, :name(wrap("--RETURN-TO--")));

class _007::Runtime {
    has $.input;
    has $.output;
    has @!frames;
    has $.builtin-opscope;
    has $.builtin-frame;

    submethod BUILD(:$!input, :$!output) {
        self.enter(NO_OUTER, wrap({}), create(TYPE<Q::StatementList>,
            :statements(wrap([])),
        ));
        $!builtin-frame = @!frames[*-1];
        $!builtin-opscope = _007::OpScope.new;
        self.load-builtins;
    }

    method run(_007::Object $compunit) {
        bound-method($compunit, "run", self)();
        CATCH {
            when X::Control::Return {
                die X::ControlFlow::Return.new;
            }
        }
    }

    method enter($outer-frame, $static-lexpad, $statementlist, $routine?) {
        my $frame = wrap({
            :$outer-frame,
            :pad(wrap({}))
        });
        @!frames.push($frame);
        for $static-lexpad.value.kv -> $name, $value {
            my $identifier = create(TYPE<Q::Identifier>, :name(wrap($name)));
            self.declare-var($identifier, $value);
        }
        for $statementlist.properties<statements>.value.kv -> $i, $_ {
            if .is-a("Q::Statement::Sub") {
                my $name = .properties<identifier>.properties<name>;
                my $parameterlist = .properties<block>.properties<parameterlist>;
                my $statementlist = .properties<block>.properties<statementlist>;
                my $static-lexpad = .properties<block>.properties<static-lexpad>;
                my $outer-frame = $frame;
                my $val = create(TYPE<Sub>,
                    :$name,
                    :$parameterlist,
                    :$statementlist,
                    :$static-lexpad,
                    :$outer-frame
                );
                self.declare-var(.properties<identifier>, $val);
            }
        }
        if $routine {
            my $name = $routine.properties<name>;
            my $identifier = create(TYPE<Q::Identifier>, :$name, :$frame);
            self.declare-var($identifier, $routine);
        }
    }

    method leave {
        @!frames.pop;
    }

    method unroll-to($frame) {
        until self.current-frame === $frame {
            self.leave;
        }
    }

    method current-frame {
        @!frames[*-1];
    }

    method !find-pad(Str $symbol, $frame is copy) {
        self!maybe-find-pad($symbol, $frame)
            // die X::Undeclared.new(:$symbol);
    }

    method !maybe-find-pad(Str $symbol, $frame is copy) {
        if $frame === NONE {
            $frame = self.current-frame;
        }
        repeat until $frame === NO_OUTER {
            return $frame.value<pad>
                if $frame.value<pad>.value{$symbol} :exists;
            $frame = $frame.value<outer-frame>;
        }
    }

    method put-var(_007::Object $identifier, $value) {
        my $name = $identifier.properties<name>.value;
        my $frame = $identifier.properties<frame> === NONE
            ?? self.current-frame
            !! $identifier.properties<frame>;
        my $pad = self!find-pad($name, $frame);
        $pad.value{$name} = $value;
    }

    method get-var(Str $name, $frame = self.current-frame) {
        my $pad = self!find-pad($name, $frame);
        return $pad.value{$name};
    }

    method maybe-get-var(Str $name, $frame = self.current-frame) {
        if self!maybe-find-pad($name, $frame) -> $pad {
            return $pad.value{$name};
        }
    }

    method declare-var(_007::Object $identifier, $value?) {
        my $name = $identifier.properties<name>.value;
        my _007::Object::Wrapped $frame = $identifier.properties<frame> === NONE
            ?? self.current-frame
            !! $identifier.properties<frame>;
        $frame.value<pad>.value{$name} = $value // NONE;
    }

    method declared($name) {
        so self!maybe-find-pad($name, self.current-frame);
    }

    method declared-locally($name) {
        my $frame = self.current-frame;
        return True
            if $frame.value<pad>.value{$name} :exists;
    }

    method register-subhandler {
        self.declare-var(RETURN_TO, $.current-frame);
    }

    method load-builtins {
        my $opscope = $!builtin-opscope;
        for builtins(:$.input, :$.output, :$opscope, :runtime(self)) -> Pair (:key($name), :$value) {
            my $identifier = create(TYPE<Q::Identifier>, :name(wrap($name)));
            self.declare-var($identifier, $value);
        }
    }

    method put-property($obj, Str $propname, $newvalue) {
        if !$obj.is-a("Dict") {
            die "We don't handle assigning to non-Dict types yet";
        }
        else {
            $obj.value{$propname} = $newvalue;
        }
    }
}
