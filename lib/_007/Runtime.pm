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
                my $name = .identifier.name.value;
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
                self.declare-var($name, $val);
            }
        }
        if $block ~~ Val::Sub {
            self.declare-var($block.name, $block);
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

    method sigbind($type, Val::Block $c, @arguments) {
        my $paramcount = $c.parameterlist.parameters.elements.elems;
        my $argcount = @arguments.elems;
        die X::ParameterMismatch.new(:$type, :$paramcount, :$argcount)
            unless $paramcount == $argcount;
        self.enter($c);
        for @($c.parameterlist.parameters.elements) Z @arguments -> ($param, $arg) {
            my $name = $param.identifier.name.value;
            self.declare-var($name, $arg);
        }
    }

    multi method call(Val::Block $c, @arguments) {
        self.sigbind("Block", $c, @arguments);
        $c.statementlist.run(self);
        self.leave;
        return Val::None.new;
    }

    multi method call(Val::Sub $c, @arguments) {
        self.sigbind("Sub", $c, @arguments);
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

    multi method call(Val::Sub::Builtin $c, @arguments) {
        my $result = $c.code.(|@arguments);
        return $result if $result;
        return Val::None.new;
    }

    method property($obj, Str $propname) {
        if $obj ~~ Q {
            sub aname($attr) { $attr.name.substr(2) }
            my %known-properties = $obj.WHAT.attributes.map({ aname($_) => 1 });

            die X::PropertyNotFound.new(:$propname)
                unless %known-properties{$propname};

            return $obj."$propname"();
        }
        elsif $obj ~~ Val::Int && $propname eq "abs" {
            return Val::Sub::Builtin.new("abs", sub () {
                return Val::Int.new(:value($obj.value.abs));
            });
        }
        elsif $obj ~~ Val::Int && $propname eq "chr" {
            return Val::Sub::Builtin.new("chr", sub () {
                return Val::Str.new(:value($obj.value.chr));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "ord" {
            return Val::Sub::Builtin.new("ord", sub () {
                return Val::Int.new(:value($obj.value.ord));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "chars" {
            return Val::Sub::Builtin.new("chars", sub () {
                return Val::Int.new(:value($obj.value.chars));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "uc" {
            return Val::Sub::Builtin.new("uc", sub () {
                return Val::Str.new(:value($obj.value.uc));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "lc" {
            return Val::Sub::Builtin.new("lc", sub () {
                return Val::Str.new(:value($obj.value.lc));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "trim" {
            return Val::Sub::Builtin.new("trim", sub () {
                return Val::Str.new(:value($obj.value.trim));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "elems" {
            return Val::Sub::Builtin.new("elems", sub () {
                return Val::Int.new(:value($obj.elements.elems));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "reverse" {
            return Val::Sub::Builtin.new("reverse", sub () {
                return Val::Array.new(:elements($obj.elements.reverse));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "sort" {
            return Val::Sub::Builtin.new("sort", sub () {
                return Val::Array.new(:elements($obj.elements.sort));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "concat" {
            return Val::Sub::Builtin.new("concat", sub ($array) {
                die X::TypeCheck.new(:operation<concat>, :got($array), :expected(Val::Array))
                    unless $array ~~ Val::Array;
                return Val::Array.new(:elements([|$obj.elements , |$array.elements]));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "join" {
            return Val::Sub::Builtin.new("join", sub ($sep) {
                return Val::Str.new(:value($obj.elements.join($sep.value.Str)));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "split" {
            return Val::Sub::Builtin.new("split", sub ($sep) {
                my @elements = (Val::Str.new(:value($_)) for $obj.value.split($sep.value));
                return Val::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "index" {
            return Val::Sub::Builtin.new("index", sub ($substr) {
                return Val::Int.new(:value($obj.value.index($substr.value) // -1));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "substr" {
            return Val::Sub::Builtin.new("substr", sub ($pos, $chars?) {
                return Val::Str.new(:value($obj.value.substr(
                    $pos.value,
                    $chars.defined
                        ?? $chars.value
                        !! $obj.value.chars)));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "charat" {
            return Val::Sub::Builtin.new("charat", sub ($pos) {
                my $s = $obj.value;

                die X::Subscript::TooLarge.new(:value($pos.value), :length($s.chars))
                    if $pos.value >= $s.chars;

                return Val::Str.new(:value($s.substr($pos.value, 1)));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "filter" {
            return Val::Sub::Builtin.new("filter", sub ($fn) {
                my @elements = $obj.elements.grep({ self.call($fn, [$_]).truthy });
                return Val::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "map" {
            return Val::Sub::Builtin.new("map", sub ($fn) {
                my @elements = $obj.elements.map({ self.call($fn, [$_]) });
                return Val::Array.new(:@elements);
            });
        }
        elsif $obj ~~ (Q | Val::Object) && ($obj.properties{$propname} :exists) {
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
            return Val::Sub::Builtin.new("extend", sub ($newprops) {
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
