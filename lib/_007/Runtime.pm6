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

sub aname($attr) { $attr.name.substr(2) }
sub avalue($attr, $obj) { $attr.get_value($obj) }

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
        self.run-q($compunit.block.statementlist);
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
            if is-func($main) {
                self.call($main, @!arguments.map(&make-str));

                CATCH {
                    when X::ParameterMismatch {
                        my @main-parameters = get-all-array-elements(
                            $main.slots<parameterlist>.parameters
                        ).map(*.identifier.name.native-value);
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
                self.declare-var(.identifier, make-func(
                    .identifier.name,
                    .block.parameterlist,
                    .block.statementlist,
                    $frame,
                    .block.static-lexpad,
                ));
            }
        }
        if $routine {
            my $name = $routine.slots<name>;
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
        self.run-q($block.statementlist);
        self.leave;
    }

    method call($c where &is-callable, @arguments) {
        if $c === $!say-builtin {
            for @arguments -> $argument {
                $.output.print($argument.Str);
            }
            $.output.print("\n");
            return NONE;
        }
        else {
            my $paramcount = $c ~~ _007::Value::Backed
                ?? $c.native-value[2].elems
                !! get-array-length($c.slots<parameterlist>.parameters);
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
        my $value;
        if $c ~~ _007::Value::Backed {
            $value = $c.native-value[0](|@arguments);
        }
        else {
            self.enter($c.slots<outer-frame>, $c.slots<static-lexpad>, $c.slots<statementlist>, $c);
            for @(get-all-array-elements($c.slots<parameterlist>.parameters)) Z @arguments -> ($param, $arg) {
                self.declare-var($param.identifier, $arg);
            }
            self.register-subhandler;
            my $frame = self.current-frame;
            $value = self.run-q($c.slots<statementlist>);
            self.leave;
            CATCH {
                when X::Control::Return {
                    self.unroll-to($frame);
                    self.leave;
                    return .value;
                }
            }
        }
        return $value;
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
            my @parameters = &fn.signature.params».name».&ditch-sigil».&parameter;
            return make-func(&fn, $name, @parameters);
        }

        my $type = Val::Type.of($obj.WHAT).name;
        if $obj ~~ Q {
            if $propname eq "detach" {

                sub interpolate($thing) {
                    return make-array(get-all-array-elements($thing).map(&interpolate).Array)
                        if is-array($thing);

                    return make-dict(get-all-dict-properties($thing).map({ .key => interpolate(.value) }).Array)
                        if is-dict($thing);

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

                my $s = $obj.native-value;

                die X::Subscript::TooLarge.new(:value($pos.native-value), :length($s.chars))
                    if $pos.native-value >= $s.chars + 1;

                die X::Subscript::Negative.new(:value($pos.native-value))
                    if $pos.native-value < 0;

                return make-str($s.substr($pos.native-value, $chars.native-value));
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
        elsif is-regex($obj) && $propname eq "fullmatch" {
            return builtin(sub fullmatch($str) {
                die X::Regex::InvalidMatchType.new
                    unless is-str($str);

                return make-bool(regex-fullmatch($obj, $str.native-value));
            });
        }
        elsif is-regex($obj) && $propname eq "search" {
            return builtin(sub search($str) {
                die X::Regex::InvalidMatchType.new
                    unless is-str($str);

                return make-bool(regex-search($obj, $str.native-value));
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
        elsif is-func($obj) && $propname eq any <outer-frame static-lexpad parameterlist statementlist> {
            if $obj ~~ _007::Value::Backed {
                die "XXX It's a backed func -- if the test suite passes with this `die` intact, we should have more tests";
            }
            else {
                $obj.slots{$propname};
            }
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

    multi method eval-q(Q::Expr $expr) {
        die "Unhandled Q::Expr type ", $expr.^name;
    }

    multi method eval-q(Q::Literal::None $) {
        NONE;
    }

    multi method eval-q(Q::Literal::Bool $bool) {
        $bool.value;
    }

    multi method eval-q(Q::Literal::Int $int) {
        $int.value;
    }

    multi method eval-q(Q::Literal::Str $str) {
        $str.value;
    }

    multi method eval-q(Q::Term::Identifier $identifier) {
        self.get-var($identifier.name.native-value);
    }

    multi method eval-q(Q::Term::Identifier::Direct $direct) {
        self.get-direct($direct.frame, $direct.name.native-value);
    }

    multi method eval-q(Q::Regex::Identifier $identifier) {
        # XXX check that the value is a string
        self.eval-q($identifier.identifier);
    }

    multi method eval-q(Q::Term::Regex $regex) {
        make-regex($regex.contents);
    }

    multi method eval-q(Q::Term::Array $array) {
        make-array(get-all-array-elements($array.elements).map({ self.eval-q($_) }).Array);
    }

    multi method eval-q(Q::Term::Object $object) {
        if is-type($object.type) {
            if $object.type === TYPE<Int> {
                my $native-value = self.eval-q(get-array-element($object.propertylist.properties, 0).value).native-value;
                return make-int($native-value);
            }
            elsif $object.type === TYPE<Array> {
                my $native-value = get-all-array-elements(
                    self.eval-q(get-array-element($object.propertylist.properties, 0).value)
                );
                return make-array($native-value);
            }
            elsif $object.type === TYPE<Dict> {
                my @properties = get-all-array-elements($object.propertylist.properties).map({
                    .key.native-value => self.eval-q(.value)
                });
                return make-dict(@properties);
            }
            elsif $object.type === TYPE<Str> {
                my $native-value = self.eval-q(get-array-element($object.propertylist.properties, 0).value).native-value;
                return make-str($native-value);
            }
            elsif $object.type === TYPE<Exception> {
                my $message = self.eval-q(get-array-element($object.propertylist.properties, 0).value);
                return make-exception($message);
            }
            elsif $object.type === TYPE<Object> {
                return make-object();
            }
            else {
                die "Don't know how to create an object of type ", $object.type.slots<name>;
            }
        }
        $object.type.create(
            get-all-array-elements($object.propertylist.properties).map({.key.native-value => self.eval-q(.value)})
        );
    }

    multi method eval-q(Q::Term::Dict $dict) {
        make-dict(
            get-all-array-elements($dict.propertylist.properties).map({.key.native-value => self.eval-q(.value)}).Array
        );
    }

    multi method eval-q(Q::Term::Func $func) {
        my $name = is-none($func.identifier)
            ?? make-str("")
            !! $func.identifier.name;
        return make-func(
            $name,
            $func.block.parameterlist,
            $func.block.statementlist,
            self.current-frame,
            $func.block.static-lexpad,
        );
    }

    multi method eval-q(Q::Prefix $prefix) {
        my $e = self.eval-q($prefix.operand);
        my $c = self.eval-q($prefix.identifier);
        return self.call($c, [$e]);
    }

    multi method eval-q(Q::Infix $infix) {
        my $l = self.eval-q($infix.lhs);
        my $r = self.eval-q($infix.rhs);
        my $c = self.eval-q($infix.identifier);
        return self.call($c, [$l, $r]);
    }

    multi method eval-q(Q::Infix::Assignment $assignment) {
        my $value = self.eval-q($assignment.rhs);
        $assignment.lhs.put-value($value, self);
        return $value;
    }

    multi method eval-q(Q::Infix::Or $or) {
        my $l = self.eval-q($or.lhs);
        return $l.truthy
            ?? $l
            !! self.eval-q($or.rhs);
    }

    multi method eval-q(Q::Infix::DefinedOr $defined-or) {
        my $l = self.eval-q($defined-or.lhs);
        return $l !=== NONE
            ?? $l
            !! self.eval-q($defined-or.rhs);
    }

    multi method eval-q(Q::Infix::And $and) {
        my $l = self.eval-q($and.lhs);
        return !$l.truthy
            ?? $l
            !! self.eval-q($and.rhs);
    }

    multi method eval-q(Q::Postfix $postfix) {
        my $e = self.eval-q($postfix.operand);
        my $c = self.eval-q($postfix.identifier);
        return self.call($c, [$e]);
    }

    multi method eval-q(Q::Postfix::Index $op) {
        given self.eval-q($op.operand) {
            when &is-array {
                my $index = self.eval-q($op.index);
                die X::Subscript::NonInteger.new
                    unless is-int($index);
                my $length = get-array-length($_);
                die X::Subscript::TooLarge.new(:value($index.native-value), :$length)
                    if $index.native-value >= $length;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.native-value < 0;
                return get-array-element($_, $index.native-value);
            }
            when &is-dict {
                my $property = self.eval-q($op.index);
                die X::Subscript::NonString.new
                    unless is-str($property);
                my $propname = $property.native-value;
                die X::Property::NotFound.new(:$propname, :type(_007::Value))
                    unless dict-property-exists($_, $propname);
                return get-dict-property($_, $propname);
            }
            when &is-func {
                my $property = self.eval-q($op.index);
                die X::Subscript::NonString.new
                    unless is-str($property);
                my $propname = $property.native-value;
                return self.property($_, $propname);
            }
            when Q {
                my $property = self.eval-q($op.index);
                die X::Subscript::NonString.new
                    unless is-str($property);
                my $propname = $property.native-value;
                return self.property($_, $propname);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(_007::Value));
        }
    }

    multi method eval-q(Q::Postfix::Call $call) {
        my $c = self.eval-q($call.operand);
        die "macro is called at runtime"
            if is-macro($c);
        die "Trying to invoke a {$c.type.slots<name>}" # XXX: make this into an X::
            unless is-func($c);
        my @arguments = get-all-array-elements($call.argumentlist.arguments).map({ self.eval-q($_) });
        return self.call($c, @arguments);
    }

    multi method eval-q(Q::Postfix::Property $property) {
        my $obj = self.eval-q($property.operand);
        my $propname = $property.property.name.native-value;
        self.property($obj, $propname);
    }

    multi method eval-q(Q::Unquote $) {
        die "Should never hit an unquote at runtime"; # XXX: turn into X::
    }

    multi method eval-q(Q::Term::My $my) {
        return self.eval-q($my.identifier);
    }

    multi method eval-q(Q::Term::Quasi $quasi) {
        my $quasi-frame;

        sub interpolate($thing) {
            return make-array(get-all-array-elements($thing).map(&interpolate).Array)
                if is-array($thing);

            return make-dict(get-all-dict-properties($thing).map({ .key => interpolate(.value) }).Array)
                if is-dict($thing);

            return $thing
                if $thing ~~ _007::Value::Backed;

            return $thing
                if $thing === TRUE | FALSE | NONE;

            die "Unknown ", $thing.type.Str
                if $thing ~~ _007::Value;

            return $thing
                if $thing ~~ Val;

            if $thing ~~ Q::Term::Identifier {
                if self.lookup-frame-outside($thing, $quasi-frame) -> $frame {
                    return Q::Term::Identifier::Direct.new(:name($thing.name), :$frame);
                }
                else {
                    return $thing;
                }
            }

            return $thing.new(:name($thing.name))
                if $thing ~~ Q::Identifier;

            if $thing ~~ Q::Unquote::Prefix {
                my $prefix = self.eval-q($thing.expr);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($prefix), :expected(Q::Prefix))
                    unless $prefix ~~ Q::Prefix;
                return $prefix.new(:identifier($prefix.identifier), :operand($thing.operand));
            }
            elsif $thing ~~ Q::Unquote::Infix {
                my $infix = self.eval-q($thing.expr);
                die X::TypeCheck.new(:operation("interpolating an unquote"), :got($infix), :expected(Q::Infix))
                    unless $infix ~~ Q::Infix;
                return $infix.new(:identifier($infix.identifier), :lhs($thing.lhs), :rhs($thing.rhs));
            }

            if $thing ~~ Q::Unquote {
                my $ast = self.eval-q($thing.expr);
                die "Expression inside unquote did not evaluate to a Q" # XXX: turn into X::
                    unless $ast ~~ Q;
                return $ast;
            }

            if $thing ~~ Q::Term::My {
                self.declare-var($thing.identifier);
            }

            if $thing ~~ Q::Term::Func {
                self.enter(self.current-frame, make-dict(), Q::StatementList.new);
                for get-all-array-elements($thing.block.parameterlist.parameters).map(*.identifier) -> $identifier {
                    self.declare-var($identifier);
                }
            }

            if $thing ~~ Q::Block {
                self.enter(self.current-frame, make-dict(), $thing.statementlist);
            }

            my %attributes = $thing.attributes.map: -> $attr {
                aname($attr) => interpolate(avalue($attr, $thing))
            };

            if $thing ~~ Q::Term::Func || $thing ~~ Q::Block {
                self.leave();
            }

            $thing.new(|%attributes);
        }

        if $quasi.qtype.native-value eq "Q.Unquote" && $quasi.contents ~~ Q::Unquote {
            return $quasi.contents;
        }
        self.enter(self.current-frame, make-dict(), Q::StatementList.new);
        $quasi-frame = self.current-frame;
        my $r = interpolate($quasi.contents);
        self.leave();
        return $r;
    }

    multi method eval-q(Q::Expr::BlockAdapter $block-adapter) {
        self.enter(self.current-frame, $block-adapter.block.static-lexpad, $block-adapter.block.statementlist);
        my $result = self.run-q($block-adapter.block.statementlist);
        self.leave;
        return $result;
    }

    multi method run-q(Q::Statement::Expr $statement) {
        self.eval-q($statement.expr);
    }

    multi method run-q(Q::Statement::If $statement) {
        my $expr = self.eval-q($statement.expr);
        if $expr.truthy {
            my $paramcount = get-array-length($statement.block.parameterlist.parameters);
            die X::ParameterMismatch.new(
                :type("If statement"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            self.run-block($statement.block, [$expr]);
        }
        else {
            given $statement.else {
                when Q::Statement::If {
                    self.run-q($statement.else);
                }
                when Q::Block {
                    my $paramcount = get-array-length($statement.else.parameterlist.parameters);
                    die X::ParameterMismatch.new(
                        :type("Else block"), :$paramcount, :argcount("0 or 1"))
                        if $paramcount > 1;
                    self.enter(self.current-frame, $statement.else.static-lexpad, $statement.else.statementlist);
                    for @(get-all-array-elements($statement.else.parameterlist.parameters)) Z $expr -> ($param, $arg) {
                        self.declare-var($param.identifier, $arg);
                    }
                    self.run-q($statement.else.statementlist);
                    self.leave;
                }
            }
        }
    }

    multi method run-q(Q::Statement::Block $statement) {
        self.enter(self.current-frame, $statement.block.static-lexpad, $statement.block.statementlist);
        self.run-q($statement.block.statementlist);
        self.leave;
    }

    multi method run-q(Q::Statement::For $statement) {
        my $count = get-array-length($statement.block.parameterlist.parameters);
        die X::ParameterMismatch.new(
            :type("For loop"), :paramcount($count), :argcount("0 or 1"))
            if $count > 1;

        my $array = self.eval-q($statement.expr);
        die X::TypeCheck.new(:operation("for loop"), :got($array), :expected(_007::Value))
            unless is-array($array);

        for get-all-array-elements($array) -> $arg {
            self.run-block($statement.block, $count ?? [$arg] !! []);
            last if self.last-triggered;
            self.reset-triggers();
        }
        self.reset-triggers();
    }

    multi method run-q(Q::Statement::While $statement) {
        while (my $expr = self.eval-q($statement.expr)).truthy {
            my $paramcount = get-array-length($statement.block.parameterlist.parameters);
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            self.run-block($statement.block, $paramcount ?? [$expr] !! []);
            last if self.last-triggered;
            self.reset-triggers();
        }
    }

    multi method run-q(Q::Statement::Return $statement) {
        my $value = is-none($statement.expr) ?? $statement.expr !! self.eval-q($statement.expr);
        my $frame = self.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }

    multi method run-q(Q::Statement::Throw $statement) {
        my $value = is-none($statement.expr)
            ?? make-exception(make-str("Died"))
            !! self.eval-q($statement.expr);
        die X::TypeCheck.new(:got($value), :excpected(_007::Value))
            unless is-exception($value);

        die X::_007::RuntimeException.new(:msg($value.slots<message>.native-value));
    }

    multi method run-q(Q::Statement::Next $) {
        self.trigger-next();
    }

    multi method run-q(Q::Statement::Last $) {
        self.trigger-last();
    }

    multi method run-q(Q::Statement::Func $) {
        # this is just the function definition; does not run at runtime
    }

    multi method run-q(Q::Statement::Macro $) {
        # this is just the macro definition; does not run at runtime
    }

    multi method run-q(Q::Statement::BEGIN $) {
        # a BEGIN block does not run at runtime
    }

    multi method run-q(Q::Statement::Class $) {
        # a class block does not run at runtime
    }

    multi method run-q(Q::StatementList $statementlist) {
        for get-all-array-elements($statementlist.statements) -> $statement {
            my $value = self.run-q($statement);
            last if self.next-triggered || self.last-triggered;
            LAST if $statement ~~ Q::Statement::Expr {
                return $value;
            }
        }
        return NONE;
    }
}
