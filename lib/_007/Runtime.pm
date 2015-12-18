use _007::Q;
use _007::Runtime::Builtins;

class Frame {
    has $.block;
    has %.pad;
}

constant NO_OUTER = {};
constant RETURN_TO = "--RETURN-TO--";

class _007::Runtime {
    has $.output;
    has @!frames;
    has $!builtins;

    submethod BUILD(:$!output) {
        my $setting = Val::Block.new(
            :parameterlist(Q::ParameterList.new),
            :statementlist(Q::StatementList.new),
            :outer-frame(NO_OUTER));
        self.enter($setting);
        $!builtins = _007::Runtime::Builtins.new(:runtime(self));
        self.load-builtins;
    }

    method run(Q::CompUnit $compunit) {
        $compunit.run(self);
        CATCH {
            when X::Control::Return {
                die X::ControlFlow::Return.new;
            }
        }
    }

    method enter(Val::Block $block) {
        my $frame = Frame.new(:$block);
        @!frames.push($frame);
        for $block.static-lexpad.kv -> $name, $value {
            self.declare-var($name, $value);
        }
        for $block.statementlist.statements.elements.kv -> $i, $_ {
            when Q::Statement::Sub {
                my $name = .ident.name;
                my $parameterlist = .block.parameterlist;
                my $statementlist = .block.statementlist;
                my %static-lexpad = .block.static-lexpad;
                my $outer-frame = $frame;
                my $val = Val::Sub.new(
                    :$name,
                    :$parameterlist,
                    :$statementlist,
                    :%static-lexpad,
                    :$outer-frame
                );
                self.declare-var($name.value, $val);
            }
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

    method !find(Str $symbol, $frame is copy) {
        self!maybe-find($symbol, $frame)
            // die X::Undeclared.new(:$symbol);
    }

    method !maybe-find(Str $symbol, $frame is copy) {
        repeat until $frame === NO_OUTER {
            return $frame.pad
                if $frame.pad{$symbol} :exists;
            $frame = $frame.block.outer-frame;
        }
        die X::ControlFlow::Return.new
            if $symbol eq RETURN_TO;
    }

    method put-var(Str $name, $value) {
        my %pad := self!find($name, self.current-frame);
        %pad{$name} = $value;
    }

    method get-var(Str $name, $frame = self.current-frame) {
        my %pad := self!find($name, $frame);
        return %pad{$name};
    }

    method maybe-get-var(Str $name) {
        if self!maybe-find($name, self.current-frame) -> %pad {
            return %pad{$name};
        }
    }

    method declare-var(Str $name, $value?) {
        self.current-frame.pad{$name} = Val::None.new;
        if defined $value {
            self.put-var($name, $value);
        }
    }

    method declared($name) {
        so self!maybe-find($name, self.current-frame);
    }

    method declared-locally($name) {
        my $frame = self.current-frame;
        return True
            if $frame.pad{$name} :exists;
    }

    method register-subhandler {
        self.declare-var(RETURN_TO, $.current-frame);
    }

    method load-builtins {
        for $!builtins.get-builtins -> Pair (:key($name), :value($subval)) {
            self.declare-var($name, $subval);
        }
    }

    method builtin-opscope {
        return $!builtins.opscope;
    }

    method sigbind($type, Val::Block $c, @args) {
        my $paramcount = $c.parameterlist.parameters.elements.elems;
        my $argcount = @args.elems;
        die X::ParameterMismatch.new(:$type, :$paramcount, :$argcount)
            unless $paramcount == $argcount;
        self.enter($c);
        for @($c.parameterlist.parameters.elements) Z @args -> ($param, $arg) {
            my $name = $param.ident.name.value;
            self.declare-var($name, $arg);
        }
    }

    multi method call(Val::Block $c, @args) {
        self.sigbind("Block", $c, @args);
        $c.statementlist.run(self);
        self.leave;
        return Val::None.new;
    }

    multi method call(Val::Sub $c, @args) {
        self.sigbind("Sub", $c, @args);
        self.register-subhandler;
        my $frame = self.current-frame;
        $c.statementlist.run(self);
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

    method property($obj, Str $propname) {
        my $builtins = _007::Runtime::Builtins.new(:runtime(self));
        if $obj ~~ Q {
            return $builtins.property($obj, $propname);
        }
        if $obj.properties{$propname} :exists {
            return $obj.properties{$propname};
        }
        elsif $propname eq "get" {
            return Val::Sub::Builtin.new("get", sub ($prop) {
                    return self.property($obj, $prop.value);
                }
            );
        }
        elsif $propname eq "has" {
            return Val::Sub::Builtin.new("has", sub ($prop) {
                    # XXX: problem: we're not lying hard enough here. we're missing
                    #      both Q objects, which are still hard-coded into the
                    #      substrate, and the special-cased properties
                    #      <get has extend update id>
                    my $exists = $obj.properties{$prop.value} :exists ?? 1 !! 0;
                    return Val::Int.new(:value($exists));
                }
            );
        }
        elsif $propname eq "update" {
            return Val::Sub::Builtin.new("update", sub ($newprops) {
                    my @properties = $obj.properties.keys;
                    sub updated($key) {
                        $newprops.properties{$key} // $obj.properties{$key}
                    }
                    return Val::Object.new(:properties(@properties.map({
                        $_ => updated($_)
                    })));
                }
            );
        }
        elsif $propname eq "extend" {
            return Val::Sub::Builtin.new("update", sub ($newprops) {
                    my @properties = $obj.properties.keys;
                    my @newproperties = $newprops.properties.keys;
                    return Val::Object.new(:properties(|@properties.map({
                        $_ => $obj.properties{$_}
                    }), |@newproperties.map({
                        $_ => $newprops.properties{$_}
                    })));
                }
            );
        }
        elsif $propname eq "id" {
            # XXX: Make this work for Q-type objects, too.
            return $obj.id;
        }
        else {
            die X::PropertyNotFound.new(:$propname);
        }
    }
}
