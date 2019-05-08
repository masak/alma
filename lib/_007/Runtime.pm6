use _007::Val;
use _007::Value;
use _007::Q;
use _007::Builtins;
use _007::Equal;

constant NO_OUTER = make-dict();
constant RETURN_TO = Q::Identifier.new(:name(make-str("--RETURN-TO--")));
constant EXIT_SUCCESS = 0;

my %q-mappings{Any};

sub tree-walk($type) {
    my %package := $type.WHO;
    for %package.keys -> $name {
        my $subtype = ::(%package ~ "::$name");
        %q-mappings{$type} //= {};
        %q-mappings{$type}{$name} = $subtype;
        tree-walk($subtype);
    }
}

tree-walk(Q);

class _007::Runtime {
    has $.input;
    has $.output;
    has @.arguments;
    has @!frames;
    has $.builtin-opscope;
    has $.builtin-frame;
    has $!say-builtin;
    has $!prompt-builtin;
    has $!exit-builtin;
    has $.exit-code;
    has $.next-triggered;
    has $.last-triggered;

    submethod BUILD(:$!input, :$!output, :@!arguments) {
        $!builtin-opscope = opscope();
        $!builtin-frame = make-dict([
            "outer-frame" => NO_OUTER,
            "pad" => builtins-pad(),
        ]);
        @!frames.push($!builtin-frame);
        $!say-builtin = get-dict-property(builtins-pad(), "say");
        $!prompt-builtin = get-dict-property(builtins-pad(), "prompt");
        $!exit-builtin = get-dict-property(builtins-pad(), "exit");
        $!exit-code = EXIT_SUCCESS;
    }

    method run(Q::CompUnit $compunit) {
        self.enter(self.current-frame, $compunit.block.static-lexpad, $compunit.block.statementlist);
        $compunit.block.statementlist.run(self);
        self.handle-main();
        self.leave();
        CATCH {
            when X::Control::Return {
                die X::ControlFlow::Return.new;
            }
            when X::Control::Exit {
                $!exit-code = .exit-code;
            }
        }
    }

    method handle-main() {
        if self.maybe-get-var("MAIN") -> $main {
            if $main ~~ Val::Func {
                self.call($main, @!arguments.map(&make-str));

                CATCH {
                    when X::ParameterMismatch {
                        my @main-parameters = get-all-array-elements($main.parameterlist.parameters).map(*.identifier.name.native-value);
                        self.print-usage(@main-parameters);
                        $!exit-code = 1;
                    }
                }
            }
        }
    }

    method print-usage(@main-parameters) {
        $.output.print("Usage:");
        $.output.print("\n");
        $.output.print("  bin/007 <script> ");
        $.output.print(@main-parameters.map({ "<" ~ $_ ~ ">" }).join(" "));
        $.output.print("\n");
    }

    method enter($outer-frame, $static-lexpad, $statementlist, $routine?) {
        my $frame = make-dict([
            "outer-frame" => $outer-frame,
            "pad" => make-dict(),
        ]);
        @!frames.push($frame);
        for get-all-dict-properties($static-lexpad) -> Pair (:$key, :$value) {
            my $identifier = Q::Identifier.new(:name(make-str($key)));
            self.declare-var($identifier, $value);
        }
        for get-all-array-elements($statementlist.statements).kv -> $i, $_ {
            when Q::Statement::Func {
                my $name = .identifier.name;
                my $parameterlist = .block.parameterlist;
                my $statementlist = .block.statementlist;
                my $static-lexpad = .block.static-lexpad;
                my $outer-frame = $frame;
                my $val = Val::Func.new(
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
            my $identifier = Q::Identifier.new(:$name);
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
            return my $pad
                if dict-property-exists($pad = get-dict-property($frame, "pad"), $symbol);
            $frame = get-dict-property($frame, "outer-frame");
        }
        die X::ControlFlow::Return.new
            if $symbol eq RETURN_TO;
    }

    method lookup-frame-outside(Q::Term::Identifier $identifier, $quasi-frame) {
        my Str $name = $identifier.name.native-value;
        my $frame = self.current-frame;
        my $seen-quasi-frame = False;
        repeat until $frame === NO_OUTER {
            if dict-property-exists(get-dict-property($frame, "pad"), $name) {
                return $seen-quasi-frame ?? $frame !! Nil;
            }
            if $frame === $quasi-frame {
                $seen-quasi-frame = True;
            }
            $frame = get-dict-property($frame, "outer-frame");
        }
        die "something is very off with lexical lookup ($name)";    # XXX: turn into X::
    }

    method put-var(Q::Identifier $identifier, $value) {
        my $name = $identifier.name.native-value;
        my $pad = self!find-pad($name, self.current-frame);
        set-dict-property($pad, $name, $value);
    }

    method get-var(Str $name) {
        my $pad = self!find-pad($name, self.current-frame);
        get-dict-property($pad, $name);
    }

    method maybe-get-var(Str $name, $frame = self.current-frame) {
        if self!maybe-find-pad($name, $frame) -> $pad {
            get-dict-property($pad, $name);
        }
    }

    method get-direct(_007::Value $frame where &is-dict, Str $name) {
        return get-dict-property(get-dict-property($frame, "pad"), $name);
    }

    method put-direct(_007::Value $frame where &is-dict, Str $name, $value) {
        set-dict-property(get-dict-property($frame, "pad"), $name, $value);
    }

    method declare-var(Q::Identifier $identifier, $value?) {
        my $name = $identifier.name.native-value;
        set-dict-property(get-dict-property(self.current-frame, "pad"), $name, $value // NONE);
    }

    method declared($name) {
        so self!maybe-find-pad($name, self.current-frame);
    }

    method declared-locally($name) {
        return dict-property-exists(get-dict-property(self.current-frame, "pad"), $name);
    }

    method register-subhandler {
        self.declare-var(RETURN_TO, $.current-frame);
    }

    method run-block(Q::Block $block, @arguments) {
        self.enter(self.current-frame, $block.static-lexpad, $block.statementlist);
        for @(get-all-array-elements($block.parameterlist.parameters)) Z @arguments -> ($param, $arg) {
            self.declare-var($param.identifier, $arg);
        }
        $block.statementlist.run(self);
        self.leave;
    }

    method call(Val::Func $c, @arguments) {
        if $c === $!say-builtin {
            for @arguments -> $argument {
                $.output.print($argument.Str);
            }
            $.output.print("\n");
            return NONE;
        }
        else {
            my $paramcount = get-array-length($c.parameterlist.parameters);
            my $argcount = @arguments.elems;
            die X::ParameterMismatch.new(:type<Sub>, :$paramcount, :$argcount)
                unless $paramcount == $argcount || $c === $!exit-builtin && $argcount < 2;
        }
        if $c === $!prompt-builtin {
            $.output.print(@arguments[0].Str);
            $.output.flush();
            my $value = $.input.get();
            if !$value.defined {
                $.output.print("\n");
                return NONE;
            }
            return make-str($value);
        }
        if $c.hook -> &hook {
            return &hook(|@arguments) || NONE;
        }
        self.enter($c.outer-frame, $c.static-lexpad, $c.statementlist, $c);
        for @(get-all-array-elements($c.parameterlist.parameters)) Z @arguments -> ($param, $arg) {
            self.declare-var($param.identifier, $arg);
        }
        self.register-subhandler;
        my $frame = self.current-frame;
        my $value = $c.statementlist.run(self);
        self.leave;
        CATCH {
            when X::Control::Return {
                self.unroll-to($frame);
                self.leave;
                return .value;
            }
        }
        $value || NONE
    }

    method trigger-next() {
        $!next-triggered = True;
    }

    method trigger-last() {
        $!last-triggered = True;
    }

    method reset-triggers() {
        $!next-triggered = False;
        $!last-triggered = False;
    }

    method property($obj, Str $propname) {
        sub builtin(&fn) {
            my $name = &fn.name;
            my &ditch-sigil = { $^str.substr(1) };
            my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(make-str($^value))))) };
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameterlist = Q::ParameterList.new(:parameters(make-array(@elements)));
            my $statementlist = Q::StatementList.new();
            return Val::Func.new-builtin(&fn, $name, $parameterlist, $statementlist);
        }

        my $type = Val::Type.of($obj.WHAT).name;
        if $obj ~~ Q {
            if $propname eq "detach" {
                sub aname($attr) { $attr.name.substr(2) }
                sub avalue($attr, $obj) { $attr.get_value($obj) }

                sub interpolate($thing) {
                    return make-array(get-all-array-elements($thing).map(&interpolate).Array)
                        if is-array($thing);

                    return make-dict(get-all-dict-properties($thing).map({ .key => interpolate(.value) }).Array)
                        if is-dict($thing);

                    return $thing.new(:properties(%($thing.properties.map(.key => interpolate(.value)))))
                        if $thing ~~ Val::Dict;

                    return $thing
                        if $thing ~~ Val;

                    return Q::Term::Identifier.new(:name($thing.name))
                        if $thing ~~ Q::Term::Identifier;

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
        elsif is-int($obj) && $propname eq "abs" {
            return builtin(sub abs() {
                return make-int($obj.native-value.abs);
            });
        }
        elsif is-int($obj) && $propname eq "chr" {
            return builtin(sub chr() {
                return make-str($obj.native-value.chr);
            });
        }
        elsif is-str($obj) && $propname eq "ord" {
            return builtin(sub ord() {
                return make-int($obj.native-value.ord);
            });
        }
        elsif is-str($obj) && $propname eq "chars" {
            return builtin(sub chars() {
                return make-int($obj.native-value.chars);
            });
        }
        elsif is-str($obj) && $propname eq "uc" {
            return builtin(sub uc() {
                return make-str($obj.native-value.uc);
            });
        }
        elsif is-str($obj) && $propname eq "lc" {
            return builtin(sub lc() {
                return make-str($obj.native-value.lc);
            });
        }
        elsif is-str($obj) && $propname eq "trim" {
            return builtin(sub trim() {
                return make-str($obj.native-value.trim);
            });
        }
        elsif is-array($obj) && $propname eq "size" {
            return builtin(sub size() {
                return make-int(get-array-length($obj));
            });
        }
        elsif is-array($obj) && $propname eq "index" {
            return builtin(sub index($value) {
                return make-int(sub () {
                    my $length = get-array-length($obj);
                    for ^$length -> $i {
                        my %*equality-seen;
                        if equal-value(get-array-element($obj, $i), $value) {
                            return $i;
                        }
                    }
                    return -1;
                }());
            });
        }
        elsif is-array($obj) && $propname eq "reverse" {
            return builtin(sub reverse() {
                return make-array(get-all-array-elements($obj).reverse.Array);
            });
        }
        elsif is-array($obj) && $propname eq "sort" {
            return builtin(sub sort() {
                my $types = get-all-array-elements($obj).map({
                    $_ ~~ _007::Value
                        ?? .type
                        !! .^name
                }).unique;
                die X::TypeCheck::HeterogeneousArray.new(:operation<sort>, :$types)
                    if $types.elems > 1;
                return make-array(get-all-array-elements($obj).sort.Array);
            });
        }
        elsif is-array($obj) && $propname eq "shuffle" {
            return builtin(sub shuffle() {
                return make-array(get-all-array-elements($obj).pick(*).Array);
            });
        }
        elsif is-array($obj) && $propname eq "concat" {
            return builtin(sub concat($array) {
                die X::TypeCheck.new(:operation<concat>, :got($array), :expected([]))
                    unless is-array($array);
                return make-array([|get-all-array-elements($obj), |get-all-array-elements($array)]);
            });
        }
        elsif is-array($obj) && $propname eq "join" {
            return builtin(sub join($sep) {
                die X::TypeCheck.new(:operation<join>, :got($sep), :expected(Str))
                    unless is-str($sep);

                return make-str(get-all-array-elements($obj).join($sep.native-value.Str));
            });
        }
        elsif is-dict($obj) && $propname eq "size" {
            return builtin(sub size() {
                return make-int(get-dict-size($obj));
            });
        }
        elsif is-str($obj) && $propname eq "split" {
            return builtin(sub split($sep) {
                die X::TypeCheck.new(:operation<split>, :got($sep), :expected(Str))
                    unless is-str($sep);

                my @elements = $obj.native-value.split($sep.native-value).map(&make-str);
                return make-array(@elements);
            });
        }
        elsif is-str($obj) && $propname eq "index" {
            return builtin(sub index($substr) {
                die X::TypeCheck.new(:operation<index>, :got($substr), :expected(Str))
                    unless is-str($substr);

                return make-int($obj.native-value.index($substr.native-value) // -1);
            });
        }
        elsif is-str($obj) && $propname eq "substr" {
            return builtin(sub substr($pos, $chars) {
                die X::TypeCheck.new(:operation<substr>, :got($pos), :expected(Str))
                    unless is-int($pos);
                die X::TypeCheck.new(:operation<substr>, :got($chars), :expected(Str))
                    unless is-int($chars);

                return make-str($obj.native-value.substr($pos.native-value, $chars.native-value));
            });
        }
        elsif is-str($obj) && $propname eq "contains" {
            return builtin(sub contains($substr) {
                die X::TypeCheck.new(:operation<contains>, :got($substr), :expected(Str))
                    unless is-str($substr);

                return make-bool($obj.native-value.contains($substr.native-value));
            });
        }
        elsif is-str($obj) && $propname eq "prefix" {
            return builtin(sub prefix($pos) {
                return make-str($obj.native-value.substr(
                    0,
                    $pos.native-value));
            });
        }
        elsif is-str($obj) && $propname eq "suffix" {
            return builtin(sub suffix($pos) {
                return make-str($obj.native-value.substr(
                    $pos.native-value));
            });
        }
        elsif is-str($obj) && $propname eq "charat" {
            return builtin(sub charat($pos) {
                my $s = $obj.native-value;

                die X::Subscript::TooLarge.new(:value($pos.native-value), :length($s.chars))
                    if $pos.native-value >= $s.chars;

                return make-str($s.substr($pos.native-value, 1));
            });
        }
        elsif $obj ~~ Val::Regex && $propname eq "fullmatch" {
            return builtin(sub fullmatch($str) {
                die X::Regex::InvalidMatchType.new
                    unless is-str($str);

                return make-bool($obj.fullmatch($str.native-value));
            });
        }
        elsif $obj ~~ Val::Regex && $propname eq "search" {
            return builtin(sub search($str) {
                die X::Regex::InvalidMatchType.new
                    unless is-str($str);

                return make-bool($obj.search($str.native-value));
            });
        }
        elsif is-array($obj) && $propname eq "filter" {
            return builtin(sub filter($fn) {
                my @elements = get-all-array-elements($obj).grep({ self.call($fn, [$_]).truthy });
                return make-array(@elements);
            });
        }
        elsif is-array($obj) && $propname eq "map" {
            return builtin(sub map($fn) {
                my @elements = get-all-array-elements($obj).map({ self.call($fn, [$_]) });
                return make-array(@elements);
            });
        }
        elsif is-array($obj) && $propname eq "flatMap" {
            return builtin(sub flatMap($fn) {
                my @elements;
                for get-all-array-elements($obj) -> $e {
                    my $r = self.call($fn, [$e]);
                    if is-array($r) {
                        @elements.push(|get-all-array-elements($r));
                    }
                    else {
                        @elements.push($r);
                    }
                }
                return make-array(@elements);
            });
        }
        elsif is-array($obj) && $propname eq "push" {
            return builtin(sub push($newelem) {
                get-all-array-elements($obj).push($newelem);
                return NONE;
            });
        }
        elsif is-array($obj) && $propname eq "pop" {
            return builtin(sub pop() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if get-array-length($obj) == 0;
                return get-all-array-elements($obj).pop();
            });
        }
        elsif is-array($obj) && $propname eq "shift" {
            return builtin(sub shift() {
                die X::Cannot::Empty.new(:action<pop>, :what($obj.^name))
                    if get-array-length($obj) == 0;
                return get-all-array-elements($obj).shift();
            });
        }
        elsif is-array($obj) && $propname eq "unshift" {
            return builtin(sub unshift($newelem) {
                get-all-array-elements($obj).unshift($newelem);
                return NONE;
            });
        }
        elsif $obj ~~ Val::Type && $propname eq "name" {
            return make-str($obj.name);
        }
        elsif is-type($obj) && $propname eq "name" {
            return make-str($obj.slots<name>);
        }
        elsif $obj ~~ Val::Type && $propname eq "create" {
            return builtin(sub create($properties) {
                $obj.create(get-all-array-elements($properties).map({
                    get-array-element($_, 0).native-value => get-array-element($_, 1)
                }));
            });
        }
        elsif is-type($obj) && $propname eq "create" {
            return builtin(sub create($properties) {
                if $obj === TYPE<Array> {
                    make-array(get-all-array-elements(get-array-element(get-array-element($properties, 0), 1)));
                }
                elsif $obj === TYPE<Bool> {
                    die X::Uninstantiable.new(:name<Bool>);
                }
                elsif $obj === TYPE<Dict> {
                    make-dict(
                        get-all-array-elements($properties).map({
                            get-array-element($_, 0) => get-array-element($_, 1)
                        }).Array
                    );
                }
                elsif $obj === TYPE<Int> {
                    make-int(get-array-element(get-array-element($properties, 0), 1).native-value);
                }
                elsif $obj === TYPE<None> {
                    die X::Uninstantiable.new(:name<None>);
                }
                elsif $obj === TYPE<Str> {
                    make-str(get-array-element(get-array-element($properties, 0), 1).native-value);
                }
                else {
                    die "Unknown type ", $obj.slots<name>;
                }
            });
        }
        elsif $obj ~~ Val::Func && $propname eq any <outer-frame static-lexpad parameterlist statementlist> {
            return $obj."$propname"();
        }
        elsif $obj ~~ Q && ($obj.properties{$propname} :exists) {
            return $obj.properties{$propname};
        }
        elsif is-dict($obj) && $propname eq "get" {
            return builtin(sub get($prop) {
                die X::TypeCheck.new(:operation<get>, :got($prop), :expected(Str))
                    unless is-str($prop);

                return get-dict-property($obj, $prop.native-value);
            });
        }
        elsif is-dict($obj) && $propname eq "keys" {
            return builtin(sub keys() {
                return make-array(get-all-dict-keys($obj).map(&make-str).Array);
            });
        }
        elsif is-dict($obj) && $propname eq "has" {
            return builtin(sub has($prop) {
                die X::TypeCheck.new(:operation<has>, :got($prop), :expected(Str))
                    unless is-str($prop);

                return make-bool(dict-property-exists($obj, $prop.native-value));
            });
        }
        elsif is-dict($obj) && $propname eq "update" {
            return builtin(sub update($newprops) {
                die X::TypeCheck.new(:operation<update>, :got($newprops), :expected(Hash))
                    unless is-dict($newprops);

                for get-all-dict-keys($obj) {
                    if dict-property-exists($newprops, $_) {
                        set-dict-property($obj, $_, get-dict-property($newprops, $_));
                    }
                }
                return $obj;
            });
        }
        elsif is-dict($obj) && $propname eq "extend" {
            return builtin(sub extend($newprops) {
                die X::TypeCheck.new(:operation<extend>, :got($newprops), :expected(Hash))
                    unless is-dict($newprops);

                for get-all-dict-keys($newprops) {
                    set-dict-property($obj, $_, get-dict-property($newprops, $_));
                }
                return $obj;
            });
        }
        elsif $obj ~~ Val::Type && (%q-mappings{$obj.type}{$propname} :exists) {
            my $subtype = %q-mappings{$obj.type}{$propname};
            return Val::Type.of($subtype);
        }
        else {
            if $obj ~~ Val::Type {
                die X::Property::NotFound.new(:$propname, :type("$type ({$obj.type.^name})"));
            }
            die X::Property::NotFound.new(:$propname, :$type);
        }
    }

    method put-property($obj, Str $propname, $newvalue) {
        if $obj ~~ Q {
            die "We don't handle assigning to Q object properties yet";
        }
        elsif !is-dict($obj) {
            die "We don't handle assigning to non-Dict types yet";
        }
        else {
            $obj.properties{$propname} = $newvalue;
        }
    }
}
