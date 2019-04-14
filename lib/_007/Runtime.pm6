use _007::Val;
use _007::Q;
use _007::Builtins;
use _007::Equal;

constant NO_OUTER = Val::Dict.new;
constant RETURN_TO = Q::Identifier.new(:name(Val::Str.new(:value("--RETURN-TO--"))));
constant EXIT_SUCCESS = 0;

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

    submethod BUILD(:$!input, :$!output, :@!arguments) {
        $!builtin-opscope = opscope();
        $!builtin-frame = Val::Dict.new(:properties(
            :outer-frame(NO_OUTER),
            :pad(builtins-pad()))
        );
        @!frames.push($!builtin-frame);
        $!say-builtin = builtins-pad().properties<say>;
        $!prompt-builtin = builtins-pad().properties<prompt>;
        $!exit-builtin = builtins-pad().properties<exit>;
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
            if $main ~~ Val::Func {
                self.call($main, @!arguments.map(-> $value {
                    Val::Str.new(:$value)
                }));

                CATCH {
                    when X::ParameterMismatch {
                        my @main-parameters = $main.parameterlist.parameters.elements.map(*.identifier.name.value);
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
        my $frame = Val::Dict.new(:properties(:$outer-frame, :pad(Val::Dict.new)));
        @!frames.push($frame);
        for $static-lexpad.properties.kv -> $name, $value {
            my $identifier = Q::Identifier.new(:name(Val::Str.new(:value($name))));
            self.declare-var($identifier, $value);
        }
        for $statementlist.statements.elements.kv -> $i, $_ {
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
        if $frame ~~ Val::None {    # XXX: make a `defined` method on None so we can use `//`
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

    method lookup-frame-outside(Q::Term::Identifier $identifier, $quasi-frame) {
        my Str $name = $identifier.name.value;
        my $frame = self.current-frame;
        my $seen-quasi-frame = False;
        repeat until $frame === NO_OUTER {
            if $frame.properties<pad>.properties{$name} :exists {
                return $seen-quasi-frame ?? $frame !! Nil;
            }
            if $frame === $quasi-frame {
                $seen-quasi-frame = True;
            }
            $frame = $frame.properties<outer-frame>;
        }
        die "something is very off with lexical lookup ($name)";    # XXX: turn into X::
    }

    method put-var(Q::Identifier $identifier, $value) {
        my $name = $identifier.name.value;
        my $pad = self!find-pad($name, self.current-frame);
        $pad.properties{$name} = $value;
    }

    method get-var(Str $name) {
        my $pad = self!find-pad($name, self.current-frame);
        return $pad.properties{$name};
    }

    method maybe-get-var(Str $name, $frame = self.current-frame) {
        if self!maybe-find-pad($name, $frame) -> $pad {
            return $pad.properties{$name};
        }
    }

    method get-direct(Val::Dict $frame, Str $name) {
        return $frame.properties<pad>.properties{$name};
    }

    method put-direct(Val::Dict $frame, Str $name, $value) {
        $frame.properties<pad>.properties{$name} = $value;
    }

    method declare-var(Q::Identifier $identifier, $value?) {
        my $name = $identifier.name.value;
        self.current-frame.properties<pad>.properties{$name} = $value // NONE;
    }

    method declared($name) {
        so self!maybe-find-pad($name, self.current-frame);
    }

    method declared-locally($name) {
        return so (self.current-frame.properties<pad>.properties{$name} :exists);
    }

    method register-subhandler {
        self.declare-var(RETURN_TO, $.current-frame);
    }

    method run-block(Q::Block $block, @arguments) {
        self.enter(self.current-frame, $block.static-lexpad, $block.statementlist);
        for @($block.parameterlist.parameters.elements) Z @arguments -> ($param, $arg) {
            self.declare-var($param.identifier, $arg);
        }
        self.run-q($block.statementlist);
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
            my $paramcount = $c.parameterlist.parameters.elements.elems;
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
            return Val::Str.new(:$value);
        }
        if $c.hook -> &hook {
            return &hook(|@arguments) || NONE;
        }
        self.enter($c.outer-frame, $c.static-lexpad, $c.statementlist, $c);
        for @($c.parameterlist.parameters.elements) Z @arguments -> ($param, $arg) {
            self.declare-var($param.identifier, $arg);
        }
        self.register-subhandler;
        my $frame = self.current-frame;
        my $value = self.run-q($c.statementlist);
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

    method property($obj, Str $propname) {
        sub builtin(&fn) {
            my $name = &fn.name;
            my &ditch-sigil = { $^str.substr(1) };
            my &parameter = { Q::Parameter.new(:identifier(Q::Identifier.new(:name(Val::Str.new(:$^value))))) };
            my @elements = &fn.signature.params».name».&ditch-sigil».&parameter;
            my $parameterlist = Q::ParameterList.new(:parameters(Val::Array.new(:@elements)));
            my $statementlist = Q::StatementList.new();
            return Val::Func.new-builtin(&fn, $name, $parameterlist, $statementlist);
        }

        my $type = Val::Type.of($obj.WHAT).name;
        if $obj ~~ Q {
            if $propname eq "detach" {

                sub interpolate($thing) {
                    return $thing.new(:elements($thing.elements.map(&interpolate)))
                        if $thing ~~ Val::Array;

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
        elsif $obj ~~ Val::Array && $propname eq "size" {
            return builtin(sub size() {
                return Val::Int.new(:value($obj.elements.elems));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "index" {
            return builtin(sub index($value) {
                return Val::Int.new(:value(sub () {
                    for ^$obj.elements.elems -> $i {
                        my %*equality-seen;
                        if equal-value($obj.elements[$i], $value) {
                            return $i;
                        }
                    }
                    return -1;
                }()));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "reverse" {
            return builtin(sub reverse() {
                return Val::Array.new(:elements($obj.elements.reverse));
            });
        }
        elsif $obj ~~ Val::Array && $propname eq "sort" {
            return builtin(sub sort() {
                my $types = $obj.elements.map({ .^name }).unique;
                die X::TypeCheck::HeterogeneousArray.new(:operation<sort>, :$types)
                    if $types.elems > 1;
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
        elsif $obj ~~ Val::Dict && $propname eq "size" {
            return builtin(sub size() {
                return Val::Int.new(:value($obj.properties.elems));
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

                return Val::Bool.new(:value(
                        $obj.value.contains($substr.value)
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
                die X::Regex::InvalidMatchType.new
                    unless $str ~~ Val::Str;

                return Val::Bool.new(:value($obj.fullmatch($str.value)));
            });
        }
        elsif $obj ~~ Val::Regex && $propname eq "search" {
            return builtin(sub search($str) {
                die X::Regex::InvalidMatchType.new
                    unless $str ~~ Val::Str;

                return Val::Bool.new(:value($obj.search($str.value)));
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
        elsif $obj ~~ Val::Array && $propname eq "flatMap" {
            return builtin(sub flatMap($fn) {
                my @elements;
                for $obj.elements -> $e {
                    my $r = self.call($fn, [$e]);
                    if $r ~~ Val::Array {
                        @elements.push(|$r.elements);
                    }
                    else {
                        @elements.push($r);
                    }
                }
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
        elsif $obj ~~ Val::Type && $propname eq "create" {
            return builtin(sub create($properties) {
                $obj.create($properties.elements.map({ .elements[0].value => .elements[1] }));
            });
        }
        elsif $obj ~~ Val::Func && $propname eq any <outer-frame static-lexpad parameterlist statementlist> {
            return $obj."$propname"();
        }
        elsif $obj ~~ Q && ($obj.properties{$propname} :exists) {
            return $obj.properties{$propname};
        }
        elsif $obj ~~ Val::Dict && $propname eq "get" {
            return builtin(sub get($prop) {
                return $obj.properties{$prop.value};
            });
        }
        elsif $obj ~~ Val::Dict && $propname eq "keys" {
            return builtin(sub keys() {
                return Val::Array.new(:elements($obj.properties.keys.map({
                    Val::Str.new(:$^value)
                })));
            });
        }
        elsif $obj ~~ Val::Dict && $propname eq "has" {
            return builtin(sub has($prop) {
                my $value = $obj.properties{$prop.value} :exists;
                return Val::Bool.new(:$value);
            });
        }
        elsif $obj ~~ Val::Dict && $propname eq "update" {
            return builtin(sub update($newprops) {
                for $obj.properties.keys {
                    $obj.properties{$_} = $newprops.properties{$_} // $obj.properties{$_};
                }
                return $obj;
            });
        }
        elsif $obj ~~ Val::Dict && $propname eq "extend" {
            return builtin(sub extend($newprops) {
                for $newprops.properties.keys {
                    $obj.properties{$_} = $newprops.properties{$_};
                }
                return $obj;
            });
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "ArgumentList" {
            return Val::Type.of(Q::ArgumentList);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Block" {
            return Val::Type.of(Q::Block);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "CompUnit" {
            return Val::Type.of(Q::CompUnit);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Identifier" {
            return Val::Type.of(Q::Identifier);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Infix" {
            return Val::Type.of(Q::Infix);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Literal" {
            return Val::Type.of(Q::Literal);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "ParameterList" {
            return Val::Type.of(Q::ParameterList);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Postfix" {
            return Val::Type.of(Q::Postfix);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Prefix" {
            return Val::Type.of(Q::Prefix);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Statement" {
            return Val::Type.of(Q::Statement);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "StatementList" {
            return Val::Type.of(Q::StatementList);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q && $propname eq "Term" {
            return Val::Type.of(Q::Term);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Literal && $propname eq "Int" {
            return Val::Type.of(Q::Literal::Int);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Literal && $propname eq "None" {
            return Val::Type.of(Q::Literal::None);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Literal && $propname eq "Str" {
            return Val::Type.of(Q::Literal::Str);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Postfix && $propname eq "Call" {
            return Val::Type.of(Q::Postfix::Call);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Postfix && $propname eq "Property" {
            return Val::Type.of(Q::Postfix::Property);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Statement && $propname eq "Func" {
            return Val::Type.of(Q::Statement::Func);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Statement && $propname eq "If" {
            return Val::Type.of(Q::Statement::If);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Statement && $propname eq "Macro" {
            return Val::Type.of(Q::Statement::Macro);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Statement && $propname eq "My" {
            return Val::Type.of(Q::Statement::My);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Statement && $propname eq "Return" {
            return Val::Type.of(Q::Statement::Return);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Term && $propname eq "Array" {
            return Val::Type.of(Q::Term::Array);
        }
        elsif $obj ~~ Val::Type && $obj.type === Q::Term && $propname eq "Identifier" {
            return Val::Type.of(Q::Term::Identifier);
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
        elsif $obj !~~ Val::Dict {
            die "We don't handle assigning to non-Val::Dict types yet";
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
        self.get-var($identifier.name.value);
    }

    multi method eval-q(Q::Term::Identifier::Direct $direct) {
        self.get-direct($direct.frame, $direct.name.value);
    }

    multi method eval-q(Q::Regex::Identifier $identifier) {
        # XXX check that the value is a string
        self.eval-q($identifier.identifier);
    }

    multi method eval-q(Q::Term::Regex $regex) {
        Val::Regex.new(contents => $regex.contents);
    }

    multi method eval-q(Q::Term::Array $array) {
        Val::Array.new(:elements($array.elements.elements.map({ self.eval-q($_) })));
    }

    multi method eval-q(Q::Term::Object $object) {
        $object.type.create(
            $object.propertylist.properties.elements.map({.key.value => self.eval-q(.value)})
        );
    }

    multi method eval-q(Q::Term::Dict $dict) {
        Val::Dict.new(:properties(
            $dict.propertylist.properties.elements.map({.key.value => self.eval-q(.value)})
        ));
    }

    multi method eval-q(Q::Term::Func $func) {
        my $name = $func.identifier ~~ Val::None
            ?? Val::Str.new(:value(""))
            !! $func.identifier.name;
        return Val::Func.new(
            :$name,
            :parameterlist($func.block.parameterlist),
            :statementlist($func.block.statementlist),
            :static-lexpad($func.block.static-lexpad),
            :outer-frame(self.current-frame),
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

        my $lhs = $assignment.lhs;

        given $lhs {
            when Q::Term::Identifier::Direct {
                self.put-direct($lhs.frame, $lhs.name.value, $value);
            }
            when Q::Term::Identifier {
                self.put-var($lhs, $value);
            }
            when Q::Postfix::Index {
                given self.eval-q($lhs.operand) {
                    when Val::Array {
                        my $index = self.eval-q($lhs.index);
                        die X::Subscript::NonInteger.new
                            if $index !~~ Val::Int;
                        die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                            if $index.value >= .elements;
                        die X::Subscript::Negative.new(:$index, :type([]))
                            if $index.value < 0;
                        .elements[$index.value] = $value;
                    }
                    when Val::Dict | Q {
                        my $property = self.eval-q($lhs.index);
                        die X::Subscript::NonString.new
                            if $property !~~ Val::Str;
                        my $propname = $property.value;
                        self.put-property($_, $propname, $value);
                    }
                    die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Val::Array));
                }
            }
            when Q::Postfix::Property {
                given self.eval-q($lhs.operand) {
                    when Val::Dict | Q {
                        my $propname = $lhs.property.name.value;
                        self.put-property($_, $propname, $value);
                    }
                    die "We don't handle this case yet"; # XXX: think more about this case
                }
            }
            when Q::Term::My {
                self.put-var($lhs.identifier, $value);
            }
        }

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
            when Val::Array {
                my $index = self.eval-q($op.index);
                die X::Subscript::NonInteger.new
                    if $index !~~ Val::Int;
                die X::Subscript::TooLarge.new(:value($index.value), :length(+.elements))
                    if $index.value >= .elements;
                die X::Subscript::Negative.new(:$index, :type([]))
                    if $index.value < 0;
                return .elements[$index.value];
            }
            when Val::Dict {
                my $property = self.eval-q($op.index);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                die X::Property::NotFound.new(:$propname, :type(Val::Dict))
                    if .properties{$propname} :!exists;
                return .properties{$propname};
            }
            when Val::Func | Q {
                my $property = self.eval-q($op.index);
                die X::Subscript::NonString.new
                    if $property !~~ Val::Str;
                my $propname = $property.value;
                return self.property($_, $propname);
            }
            die X::TypeCheck.new(:operation<indexing>, :got($_), :expected(Val::Array));
        }
    }

    multi method eval-q(Q::Postfix::Call $call) {
        my $c = self.eval-q($call.operand);
        die "macro is called at runtime"
            if $c ~~ Val::Macro;
        die "Trying to invoke a {$c.^name.subst(/^'Val::'/, '')}" # XXX: make this into an X::
            unless $c ~~ Val::Func;
        my @arguments = $call.argumentlist.arguments.elements.map({ self.eval-q($_) });
        return self.call($c, @arguments);
    }

    multi method eval-q(Q::Postfix::Property $property) {
        my $obj = self.eval-q($property.operand);
        my $propname = $property.property.name.value;
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
            return $thing.new(:elements($thing.elements.map(&interpolate)))
                if $thing ~~ Val::Array;

            return $thing.new(:properties(%($thing.properties.map({ .key => interpolate(.value) }))))
                if $thing ~~ Val::Dict;

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
                self.enter(self.current-frame, Val::Dict.new, Q::StatementList.new);
                for $thing.block.parameterlist.parameters.elements.map(*.identifier) -> $identifier {
                    self.declare-var($identifier);
                }
            }

            if $thing ~~ Q::Block {
                self.enter(self.current-frame, Val::Dict.new, $thing.statementlist);
            }

            my %attributes = $thing.attributes.map: -> $attr {
                aname($attr) => interpolate(avalue($attr, $thing))
            };

            if $thing ~~ Q::Term::Func || $thing ~~ Q::Block {
                self.leave();
            }

            $thing.new(|%attributes);
        }

        if $quasi.qtype.value eq "Q.Unquote" && $quasi.contents ~~ Q::Unquote {
            return $quasi.contents;
        }
        self.enter(self.current-frame, Val::Dict.new, Q::StatementList.new);
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
            my $paramcount = $statement.block.parameterlist.parameters.elements.elems;
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
                    my $paramcount = $statement.else.parameterlist.parameters.elements.elems;
                    die X::ParameterMismatch.new(
                        :type("Else block"), :$paramcount, :argcount("0 or 1"))
                        if $paramcount > 1;
                    self.enter(self.current-frame, $statement.else.static-lexpad, $statement.else.statementlist);
                    for @($statement.else.parameterlist.parameters.elements) Z $expr -> ($param, $arg) {
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
        my $paramcount = $statement.block.parameterlist.parameters.elements.elems;
        die X::ParameterMismatch.new(
            :type("For loop"), :$paramcount, :argcount("0 or 1"))
            if $paramcount > 1;

        my $got = self.eval-q($statement.expr);
        die X::TypeCheck.new(:operation("for loop"), :$got, :expected(Val::Array))
            unless $got ~~ Val::Array;

        for $got.elements -> $arg {
            self.run-block($statement.block, $paramcount ?? [$arg] !! []);
        }
    }

    multi method run-q(Q::Statement::While $statement) {
        while (my $expr = self.eval-q($statement.expr)).truthy {
            my $paramcount = $statement.block.parameterlist.parameters.elements.elems;
            die X::ParameterMismatch.new(
                :type("While loop"), :$paramcount, :argcount("0 or 1"))
                if $paramcount > 1;
            self.run-block($statement.block, $paramcount ?? [$expr] !! []);
        }
    }

    multi method run-q(Q::Statement::Return $statement) {
        my $value = $statement.expr ~~ Val::None ?? $statement.expr !! self.eval-q($statement.expr);
        my $frame = self.get-var("--RETURN-TO--");
        die X::Control::Return.new(:$value, :$frame);
    }

    multi method run-q(Q::Statement::Throw $statement) {
        my $value = $statement.expr ~~ Val::None
            ?? Val::Exception.new(:message(Val::Str.new(:value("Died"))))
            !! self.eval-q($statement.expr);
        die X::TypeCheck.new(:got($value), :excpected(Val::Exception))
            if $value !~~ Val::Exception;

        die X::_007::RuntimeException.new(:msg($value.message.value));
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
        for $statementlist.statements.elements -> $statement {
            my $value = self.run-q($statement);
            LAST if $statement ~~ Q::Statement::Expr {
                return $value;
            }
        }
        return NONE;
    }
}
