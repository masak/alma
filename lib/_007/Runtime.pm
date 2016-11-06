use _007::Q;
use _007::Runtime::Builtins;
use _007::OpScope;

constant NO_OUTER = Val::Object.new;
constant RETURN_TO = Q::Identifier.new(
    :name(Val::Str.new(:value("--RETURN-TO--"))),
    :frame(NONE));

class _007::Runtime {
    has $.input;
    has $.output;
    has @!frames;
    has $.builtin-opscope;
    has $.builtin-frame;

    submethod BUILD(:$!input, :$!output) {
        self.enter(NO_OUTER, Val::Object.new, Q::StatementList.new);
        $!builtin-frame = @!frames[*-1];
        $!builtin-opscope = _007::OpScope.new;
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

    method enter($outer-frame, $static-lexpad, $statementlist, $routine?) {
        my $frame = Val::Object.new(:properties(:$outer-frame, :pad(Val::Object.new)));
        @!frames.push($frame);
        for $static-lexpad.properties.kv -> $name, $value {
            my $identifier = Q::Identifier.new(
                :name(Val::Str.new(:value($name))),
                :frame(NONE));
            self.declare-var($identifier, $value);
        }
        for $statementlist.statements.elements.kv -> $i, $_ {
            when Q::Statement::Sub {
                my $name = .identifier.name;
                my $parameterlist = .block.parameterlist;
                my $statementlist = .block.statementlist;
                my $static-lexpad = .block.static-lexpad;
                my $outer-frame = $frame;
                my $val = Val::Sub.new(
                    :$name,
                    :$parameterlist,
                    :$statementlist,
                    :$static-lexpad,
                    :$outer-frame
                );
                self.declare-var(.identifier, $val);
            }
        }
        if $routine {
            my $name = $routine.name;
            my $identifier = Q::Identifier.new(:$name, :$frame);
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
        if $frame ~~ Val::NoneType {    # XXX: make a `defined` method on NoneType so we can use `//`
            $frame = self.current-frame;
        }
        repeat until $frame === NO_OUTER {
            return $frame.properties<pad>
                if $frame.properties<pad>.properties{$symbol} :exists;
            $frame = $frame.properties<outer-frame>;
        }
        die X::ControlFlow::Return.new
            if $symbol eq RETURN_TO;
    }

    method put-var(Q::Identifier $identifier, $value) {
        my $name = $identifier.name.value;
        my $frame = $identifier.frame ~~ Val::NoneType
            ?? self.current-frame
            !! $identifier.frame;
        my $pad = self!find-pad($name, $frame);
        $pad.properties{$name} = $value;
    }

    method get-var(Str $name, $frame = self.current-frame) {
        my $pad = self!find-pad($name, $frame);
        return $pad.properties{$name};
    }

    method maybe-get-var(Str $name, $frame = self.current-frame) {
        if self!maybe-find-pad($name, $frame) -> $pad {
            return $pad.properties{$name};
        }
    }

    method declare-var(Q::Identifier $identifier, $value?) {
        my $name = $identifier.name.value;
        my Val::Object $frame = $identifier.frame ~~ Val::NoneType
            ?? self.current-frame
            !! $identifier.frame;
        $frame.properties<pad>.properties{$name} = $value // NONE;
    }

    method declared($name) {
        so self!maybe-find-pad($name, self.current-frame);
    }

    method declared-locally($name) {
        my $frame = self.current-frame;
        return True
            if $frame.properties<pad>.properties{$name} :exists;
    }

    method register-subhandler {
        self.declare-var(RETURN_TO, $.current-frame);
    }

    method load-builtins {
        my $opscope = $!builtin-opscope;
        for builtins(:$.input, :$.output, :$opscope) -> Pair (:key($name), :$value) {
            my $identifier = Q::Identifier.new(
                :name(Val::Str.new(:value($name))),
                :frame(NONE));
            self.declare-var($identifier, $value);
        }
    }

    method call(Val::Sub $c, @arguments) {
        my $paramcount = $c.parameterlist.parameters.elements.elems;
        my $argcount = @arguments.elems;
        die X::ParameterMismatch.new(:type<Sub>, :$paramcount, :$argcount)
            unless $paramcount == $argcount;
        if $c.hook -> &hook {
            return &hook(|@arguments) || NONE;
        }
        self.enter($c.outer-frame, $c.static-lexpad, $c.statementlist, $c);
        for @($c.parameterlist.parameters.elements) Z @arguments -> ($param, $arg) {
            self.declare-var($param.identifier, $arg);
        }
        self.register-subhandler;
        my $frame = self.current-frame;
        $c.statementlist.run(self);
        self.leave;
        CATCH {
            when X::Control::Return {
                self.unroll-to($frame);
                self.leave;
                return .value;
            }
        }
        return NONE;
    }

    method property($obj, Str $propname) {
        sub builtin(&fn) {
            my $name = &fn.name;
            my &ditch-sigil = { $^str.substr(1) };
            my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(Val::Str.new(:$^value))))) };
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
            my $statementlist = Q::StatementList.new();
            return Val::Sub.new-builtin(&fn, $name, $parameterlist, $statementlist);
        }

        my $type = Val::Type.of($obj.WHAT).name;
        if $obj ~~ Q {
            if $propname eq "detach" {
                sub aname($attr) { $attr.name.substr(2) }
                sub avalue($attr, $obj) { $attr.get_value($obj) }

                sub interpolate($thing) {
                    return $thing.new(:elements($thing.elements.map(&interpolate)))
                        if $thing ~~ Val::Array;

                    return $thing.new(:properties(%($thing.properties.map(.key => interpolate(.value)))))
                        if $thing ~~ Val::Object;

                    return $thing
                        if $thing ~~ Val;

                    return $thing.new(:name($thing.name), :frame(NONE))
                        if $thing ~~ Q::Identifier;

                    return $thing
                        if $thing ~~ Q::Unquote;

                    my %attributes = $thing.attributes.map: -> $attr {
                        aname($attr) => interpolate(avalue($attr, $thing))
                    };

                    $thing.new(|%attributes);
                }

                return builtin(sub detach() {
                    return interpolate($obj);
                });
            }

            sub aname($attr) { $attr.name.substr(2) }
            my %known-properties = $obj.WHAT.attributes.map({ aname($_) => 1 });
            # XXX: hack
            if $obj ~~ Q::Block {
                %known-properties<static-lexpad> = 1;
            }

            die X::Property::NotFound.new(:$propname, :$type)
                unless %known-properties{$propname};

            return $obj."$propname"();
        }
        elsif $obj ~~ Val::Int && $propname eq "abs" {
            return builtin(sub abs() {
                return Val::Int.new(:value($obj.value.abs));
            });
        }
        elsif $obj ~~ Val::Int && $propname eq "chr" {
            return builtin(sub chr() {
                return Val::Str.new(:value($obj.value.chr));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "ord" {
            return builtin(sub ord() {
                return Val::Int.new(:value($obj.value.ord));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "chars" {
            return builtin(sub chars() {
                return Val::Int.new(:value($obj.value.chars));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "uc" {
            return builtin(sub uc() {
                return Val::Str.new(:value($obj.value.uc));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "lc" {
            return builtin(sub lc() {
                return Val::Str.new(:value($obj.value.lc));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "trim" {
            return builtin(sub trim() {
                return Val::Str.new(:value($obj.value.trim));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "elems" {
            return builtin(sub elems() {
                return Val::Int.new(:value($obj.elements.elems));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "reverse" {
            return builtin(sub reverse() {
                return Val::Array.new(:elements($obj.elements.reverse));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "sort" {
            return builtin(sub sort() {
                return Val::Array.new(:elements($obj.elements.sort));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "shuffle" {
            return builtin(sub shuffle() {
                return Val::Array.new(:elements($obj.elements.pick(*)));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "concat" {
            return builtin(sub concat($array) {
                die X::TypeCheck.new(:operation<concat>, :got($array), :expected(Val::Array))
                    unless $array ~~ Val::Array;
                return Val::Array.new(:elements([|$obj.elements , |$array.elements]));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "join" {
            return builtin(sub join($sep) {
                return Val::Str.new(:value($obj.elements.join($sep.value.Str)));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "split" {
            return builtin(sub split($sep) {
                my @elements = (Val::Str.new(:value($_)) for $obj.value.split($sep.value));
                return Val::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "index" {
            return builtin(sub index($substr) {
                return Val::Int.new(:value($obj.value.index($substr.value) // -1));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "substr" {
            return builtin(sub substr($pos, $chars) {
                return Val::Str.new(:value($obj.value.substr(
                    $pos.value,
                    $chars.value)));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "contains" {
            return builtin(sub contains($substr) {
                die X::TypeCheck.new(:operation<contains>, :got($substr), :expected(Val::Str))
                    unless $substr ~~ Val::Str;

                return Val::Int.new(:value(
                        $obj.value.contains($substr.value);
                ));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "prefix" {
            return builtin(sub prefix($pos) {
                return Val::Str.new(:value($obj.value.substr(
                    0,
                    $pos.value)));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "suffix" {
            return builtin(sub suffix($pos) {
                return Val::Str.new(:value($obj.value.substr(
                    $pos.value)));
            });
        }
        elsif $obj ~~ Val::Str && $propname eq "charat" {
            return builtin(sub charat($pos) {
                my $s = $obj.value;

                die X::Subscript::TooLarge.new(:value($pos.value), :length($s.chars))
                    if $pos.value >= $s.chars;

                return Val::Str.new(:value($s.substr($pos.value, 1)));
            });
        }
        elsif $obj ~~ Val::Regex && $propname eq "fullmatch" {
            return builtin(sub fullmatch($str) {
                my $regex-string = $obj.contents.value;

                die X::Regex::InvalidMatchType.new
                    unless $str ~~ Val::Str;

                return Val::Bool.new(:value($regex-string eq $str.value));
            });
        }
        elsif $obj ~~ Val::Regex && $propname eq "search" {
            return builtin(sub search($str) {
                my $regex-string = $obj.contents.value;

                die X::Regex::InvalidMatchType.new
                    unless $str ~~ Val::Str;

                return Val::Bool.new(:value($str.value.contains($regex-string)));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "filter" {
            return builtin(sub filter($fn) {
                my @elements = $obj.elements.grep({ self.call($fn, [$_]).truthy });
                return Val::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "map" {
            return builtin(sub map($fn) {
                my @elements = $obj.elements.map({ self.call($fn, [$_]) });
                return Val::Array.new(:@elements);
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "push" {
            return builtin(sub push($newelem) {
                $obj.elements.push($newelem);
                return NONE;
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "pop" {
            return builtin(sub pop() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if $obj.elements.elems == 0;
                return $obj.elements.pop();
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "shift" {
            return builtin(sub shift() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if $obj.elements.elems == 0;
                return $obj.elements.shift();
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "unshift" {
            return builtin(sub unshift($newelem) {
                $obj.elements.unshift($newelem);
                return NONE;
            });
        }
        elsif $obj ~~ Val::Type && $propname eq "name" {
            return Val::Str.new(:value($obj.name));
        }
        elsif $obj ~~ Val::Sub && $propname eq any <outer-frame static-lexpad parameterlist statementlist> {
            return $obj."$propname"();
        }
        elsif $obj ~~ (Q | Val::Object) && ($obj.properties{$propname} :exists) {
            return $obj.properties{$propname};
        }
        elsif $propname eq "get" {
            return builtin(sub get($prop) {
                return self.property($obj, $prop.value);
            });
        }
        elsif $propname eq "keys" {
            return builtin(sub keys() {
                return Val::Array.new(:elements($obj.properties.keys.map({
                    Val::Str.new(:$^value)
                })));
            });
        }
        elsif $propname eq "has" {
            return builtin(sub has($prop) {
                # XXX: problem: we're not lying hard enough here. we're missing
                #      both Q objects, which are still hard-coded into the
                #      substrate, and the special-cased properties
                #      <get has extend update id>
                my $value = $obj.properties{$prop.value} :exists;
                return Val::Bool.new(:$value);
            });
        }
        elsif $propname eq "update" {
            return builtin(sub update($newprops) {
                for $obj.properties.keys {
                    $obj.properties{$_} = $newprops.properties{$_} // $obj.properties{$_};
                }
                return $obj;
            });
        }
        elsif $propname eq "extend" {
            return builtin(sub extend($newprops) {
                for $newprops.properties.keys {
                    $obj.properties{$_} = $newprops.properties{$_};
                }
                return $obj;
            });
        }
        elsif $propname eq "id" {
            # XXX: Make this work for Q-type objects, too.
            return Val::Int.new(:value($obj.id));
        }
        else {
            die X::Property::NotFound.new(:$propname, :$type);
        }
    }

    method put-property($obj, Str $propname, $newvalue) {
        if $obj ~~ Q {
            die "We don't handle assigning to Q object properties yet";
        }
        elsif $obj !~~ Val::Object {
            die "We don't handle assigning to non-Val::Object types yet";
        }
        else {
            $obj.properties{$propname} = $newvalue;
        }
    }
}
