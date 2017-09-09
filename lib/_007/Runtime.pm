use _007::Val;
use _007::Q;
use _007::Builtins;
use _007::OpScope;

constant NO_OUTER = wrap({});
constant RETURN_TO = Q::Identifier.new(
    :name(wrap("--RETURN-TO--")),
    :frame(NONE));

class _007::Runtime {
    has $.input;
    has $.output;
    has @!frames;
    has $.builtin-opscope;
    has $.builtin-frame;

    submethod BUILD(:$!input, :$!output) {
        self.enter(NO_OUTER, wrap({}), Q::StatementList.new);
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
        my $frame = wrap({
            :$outer-frame,
            :pad(wrap({}))
        });
        @!frames.push($frame);
        for $static-lexpad.value.kv -> $name, $value {
            my $identifier = Q::Identifier.new(
                :name(wrap($name)),
                :frame(NONE));
            self.declare-var($identifier, $value);
        }
        for $statementlist.statements.value.kv -> $i, $_ {
            when Q::Statement::Sub {
                my $name = .identifier.name;
                my $parameterlist = .block.parameterlist;
                my $statementlist = .block.statementlist;
                my $static-lexpad = .block.static-lexpad;
                my $outer-frame = $frame;
                my $val = TYPE<Sub>.create(
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
            my $name = $routine.properties<name>;
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
        # XXX: make a `defined` method on NoneType so we can use `//`
        if $frame ~~ _007::Object && $frame.type === TYPE<NoneType> {
            $frame = self.current-frame;
        }
        repeat until $frame === NO_OUTER {
            return $frame.value<pad>
                if $frame.value<pad>.value{$symbol} :exists;
            $frame = $frame.value<outer-frame>;
        }
        die X::ControlFlow::Return.new
            if $symbol eq RETURN_TO;
    }

    method put-var(Q::Identifier $identifier, $value) {
        my $name = $identifier.name.value;
        my $frame = $identifier.frame ~~ _007::Object && $identifier.frame.type === TYPE<NoneType>
            ?? self.current-frame
            !! $identifier.frame;
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

    method declare-var(Q::Identifier $identifier, $value?) {
        my $name = $identifier.name.value;
        my _007::Object::Wrapped $frame = $identifier.frame ~~ _007::Object && $identifier.frame.type === TYPE<NoneType>
            ?? self.current-frame
            !! $identifier.frame;
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
        for builtins(:$.input, :$.output, :$opscope) -> Pair (:key($name), :$value) {
            my $identifier = Q::Identifier.new(
                :name(wrap($name)),
                :frame(NONE));
            self.declare-var($identifier, $value);
        }
    }

    method property($obj, Str $propname) {
        sub builtin(&fn) {
            my $name = &fn.name;
            my &ditch-sigil = { $^str.substr(1) };
            my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(wrap($^value))))) };
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameters = wrap(@elements);
            my $parameterlist = Q::ParameterList.new(:$parameters);
            my $statementlist = Q::StatementList.new();
            return wrap-fn(&fn, $name, $parameterlist, $statementlist);
        }

        my $type = Val::Type.of($obj.WHAT).name;
        if $obj ~~ Q {
            if $propname eq "detach" {
                sub aname($attr) { $attr.name.substr(2) }
                sub avalue($attr, $obj) { $attr.get_value($obj) }

                sub interpolate($thing) {
                    return wrap($thing.value.map(&interpolate))
                        if $thing ~~ _007::Object && $thing.type === TYPE<Array>;

                    sub interpolate-entry($_) { .key => interpolate(.value) }
                    return wrap(hash($thing.value.map(&interpolate-entry)))
                        if $thing ~~ _007::Object && $thing.type === TYPE<Dict>;

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
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Int> && $propname eq "abs" {
            return builtin(sub abs() {
                return wrap($obj.value.abs);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Int> && $propname eq "chr" {
            return builtin(sub chr() {
                return wrap($obj.value.chr);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "ord" {
            return builtin(sub ord() {
                return wrap($obj.value.ord);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "chars" {
            return builtin(sub chars() {
                return wrap($obj.value.chars);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "uc" {
            return builtin(sub uc() {
                return wrap($obj.value.uc);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "lc" {
            return builtin(sub lc() {
                return wrap($obj.value.lc);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "trim" {
            return builtin(sub trim() {
                return wrap($obj.value.trim);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "size" {
            return builtin(sub size() {
                return wrap($obj.value.elems);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "reverse" {
            return builtin(sub reverse() {
                return wrap($obj.value.reverse);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "sort" {
            return builtin(sub sort() {
                return wrap($obj.value.sort);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "shuffle" {
            return builtin(sub shuffle() {
                return wrap($obj.value.pick(*));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "concat" {
            return builtin(sub concat($array) {
                die X::TypeCheck.new(:operation<concat>, :got($array), :expected(_007::Object))
                    unless $array ~~ _007::Object && $array.type === TYPE<Array>;
                return wrap([|$obj.value, |$array.value]);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "join" {
            return builtin(sub join($sep) {
                return wrap($obj.value.join($sep.value.Str));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Dict> && $propname eq "size" {
            return builtin(sub size() {
                return wrap($obj.value.elems);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "split" {
            return builtin(sub split($sep) {
                my @elements = $obj.value.split($sep.value).map(&wrap);
                return wrap(@elements);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "index" {
            return builtin(sub index($substr) {
                return wrap($obj.value.index($substr.value) // -1);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "substr" {
            return builtin(sub substr($pos, $chars) {
                return wrap($obj.value.substr(
                    $pos.value,
                    $chars.value));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "contains" {
            return builtin(sub contains($substr) {
                die X::TypeCheck.new(:operation<contains>, :got($substr), :expected(_007::Object))
                    unless $substr ~~ _007::Object && $substr.type === TYPE<Str>;

                return wrap($obj.value.contains($substr.value));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "prefix" {
            return builtin(sub prefix($pos) {
                return wrap($obj.value.substr(
                    0,
                    $pos.value));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "suffix" {
            return builtin(sub suffix($pos) {
                return wrap($obj.value.substr(
                    $pos.value));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Str> && $propname eq "charat" {
            return builtin(sub charat($pos) {
                my $s = $obj.value;

                die X::Subscript::TooLarge.new(:value($pos.value), :length($s.chars))
                    if $pos.value >= $s.chars;

                return wrap($s.substr($pos.value, 1));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Regex> && $propname eq "fullmatch" {
            return builtin(sub fullmatch($str) {
                my $regex-string = $obj.properties<contents>.value;

                die X::Regex::InvalidMatchType.new
                    unless $str ~~ _007::Object && $str.type === TYPE<Str>;

                return wrap($regex-string eq $str.value);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Regex> && $propname eq "search" {
            return builtin(sub search($str) {
                my $regex-string = $obj.properties<contents>.value;

                die X::Regex::InvalidMatchType.new
                    unless $str ~~ _007::Object && $str.type === TYPE<Str>;

                return wrap($str.value.contains($regex-string));
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "filter" {
            return builtin(sub filter($fn) {
                # XXX: Need to typecheck here if $fn is callable
                my @elements = $obj.value.grep({ internal-call($fn, self, [$_]).truthy });
                return wrap(@elements);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "map" {
            return builtin(sub map($fn) {
                # XXX: Need to typecheck here if $fn is callable
                my @elements = $obj.value.map({ internal-call($fn, self, [$_]) });
                return wrap(@elements);
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "push" {
            return builtin(sub push($newelem) {
                $obj.value.push($newelem);
                return NONE;
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "pop" {
            return builtin(sub pop() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if $obj.value.elems == 0;
                return $obj.value.pop();
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "shift" {
            return builtin(sub shift() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if $obj.value.elems == 0;
                return $obj.value.shift();
            });
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Array> && $propname eq "unshift" {
            return builtin(sub unshift($newelem) {
                $obj.value.unshift($newelem);
                return NONE;
            });
        }
        elsif $obj ~~ _007::Type && $propname eq "name" {
            return wrap($obj.name);
        }
        elsif $obj ~~ Val::Type | _007::Type && $propname eq "name" {
            return wrap($obj.name);
        }
        elsif $obj ~~ _007::Type && $propname eq "create" {
            return builtin(sub create($properties) {
                # XXX: needs more sanity checking
                wrap($properties.value[0].value[1].value);  # XXX: won't work for non-wrapped objects
                # _007::Object.new(:value($properties.value[0].value[1].value));
            });
        }
        elsif $obj ~~ Val::Type && $propname eq "create" {
            return builtin(sub create($properties) {
                $obj.create($properties.value.map({ .value[0].value => .value[1] }));
            });
        }
        elsif $obj ~~ _007::Object && $obj.isa("Sub") && $propname eq any <outer-frame static-lexpad parameterlist statementlist> {
            return $obj.properties{$propname};
        }
        elsif $obj ~~ Q && ($obj.properties{$propname} :exists) {
            return $obj.properties{$propname};
        }
        elsif $obj ~~ _007::Object && $obj.type === TYPE<Dict> && ($obj.value{$propname} :exists) {
            return $obj.value{$propname};
        }
        elsif $propname eq "get" {
            return builtin(sub get($prop) {
                return self.property($obj, $prop.value);
            });
        }
        elsif $propname eq "keys" {
            return builtin(sub keys() {
                return wrap($obj.value.keys.map(&wrap));
            });
        }
        elsif $propname eq "has" {
            return builtin(sub has($prop) {
                # XXX: problem: we're not lying hard enough here. we're missing
                #      both Q objects, which are still hard-coded into the
                #      substrate, and the special-cased properties
                #      <get has extend update id>
                my $value = $obj.value{$prop.value} :exists;
                return wrap($value);
            });
        }
        elsif $propname eq "update" {
            return builtin(sub update($newprops) {
                for $obj.value.keys {
                    $obj.value{$_} = $newprops.value{$_} // $obj.value{$_};
                }
                return $obj;
            });
        }
        elsif $propname eq "extend" {
            return builtin(sub extend($newprops) {
                for $newprops.value.keys {
                    $obj.value{$_} = $newprops.value{$_};
                }
                return $obj;
            });
        }
        elsif $propname eq "id" {
            # XXX: Make this work for Q-type objects, too.
            return wrap($obj.id);
        }
        else {
            die X::Property::NotFound.new(:$propname, :$type);
        }
    }

    method put-property($obj, Str $propname, $newvalue) {
        if $obj ~~ Q {
            die "We don't handle assigning to Q object properties yet";
        }
        elsif $obj !~~ _007::Object || $obj.type !=== TYPE<Dict> {
            die "We don't handle assigning to non-Dict types yet";
        }
        else {
            $obj.value{$propname} = $newvalue;
        }
    }
}
