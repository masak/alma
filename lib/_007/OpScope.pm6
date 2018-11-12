use _007::Val;
use _007::Q;
use _007::Precedence;

class X::Decorator::IllegalValue is Exception {
    has Str $.decorator;
    has Str $.value;

    method message { "The value '$.value' is not compatible with the trait '$.decorator'" }
}

class X::Decorator::Conflict is Exception {
    has Str $.decorator1;
    has Str $.decorator2;

    method message { "Decorators '$.decorator1' and '$.decorator2' cannot coexist on the same routine" }
}

class X::Precedence::Incompatible is Exception {
    method message { "Trying to relate a pre/postfix operator with an infix operator" }
}

class X::Category::Unknown is Exception {
    has Str $.category;

    method message { "Unknown category '$.category'" }
}

class _007::OpScope {
    has %.ops =
        prefix => {},
        infix => {},
        postfix => {},
    ;

    has @.infixprec;
    has @.prepostfixprec;
    has $.prepostfix-boundary = 0;

    method maybe-install($identname, @decorators) {
        return unless $identname ~~ /^ (\w+) ':' (.+) /;

        my $category = ~$0;
        my $op = ~$1;

        die X::Category::Unknown.new(:$category)
            unless $category eq any(<prefix infix postfix>);

        if $category eq "infix" | "postfix" {
            my $other_category = $category eq "infix" ?? "postfix" !! "infix";
            die X::Redeclaration.new(:symbol($op))
                if $op eq any(%.ops{$other_category}.keys);
        }

        my %precedence;
        my @prec-traits = <equiv looser tighter>;
        my $assoc;
        for @decorators -> $decorator {
            # XXX: Shouldn't do lookup by name here, but lexically
            my $name = $decorator.identifier.name.value;
            if $name eq any @prec-traits {
                my $argcount = $decorator.argumentlist.arguments.elements.elems;
                die X::ParameterMismatch.new(:type("Decorator"), :paramcount(1), :$argcount)
                    unless $argcount == 1;
                my $identifier = $decorator.argumentlist.arguments.elements[0];
                my $prep = $name eq "equiv" ?? "to" !! "than";
                die "The thing your op is $name $prep must be an identifier"
                    unless $identifier ~~ Q::Identifier;
                my $s = $identifier.name;
                die "Unknown thing in '$name' trait"
                    unless $s ~~ /^ < pre in post > 'fix:' /;
                die X::Precedence::Incompatible.new
                    if $category eq ('prefix' | 'postfix') && $s ~~ /^ in/
                    || $category eq 'infix' && $s ~~ /^ < pre post >/;
                %precedence{$name} = $s;
            }
            elsif $name eq "assoc" {
                my $argcount = $decorator.argumentlist.arguments.elements.elems;
                die X::ParameterMismatch.new(:type("Decorator"), :paramcount(1), :$argcount)
                    unless $argcount == 1;
                my $string = $decorator.argumentlist.arguments.elements[0];
                die "The associativity must be a string"
                    unless $string ~~ Q::Literal::Str;
                my $value = $string.value.value;
                die X::Decorator::IllegalValue.new(:trait<assoc>, :$value)
                    unless $value eq any "left", "non", "right";
                $assoc = $value;
            }
            else {
                # XXX: should it still do this? we might decorate a function/macro for other reasons than op
                die "Unknown decorator '$name'";
            }
        }

        if %precedence.keys > 1 {
            my ($t1, $t2) = %precedence.keys.sort;
            die X::Decorator::Conflict.new(:$t1, :$t2);
        }

        self.install($category, $op, :%precedence, :$assoc);
    }

    method install($category, $op, $q?, :%precedence, :$assoc) {
        my $name = "$category:$op";
        my $identifier = Q::Identifier.new(:name(Val::Str.new(:value($name))));

        %!ops{$category}{$op} = $q !=== Any ?? $q !! {
            prefix => Q::Prefix.new(:$identifier),
            infix => Q::Infix.new(:$identifier),
            postfix => Q::Postfix.new(:$identifier),
        }{$category};

        my @namespace := $category eq 'infix' ?? @!infixprec !! @!prepostfixprec;

        for @namespace {
            .ops{$name} :delete;
        }

        sub new-prec {
            _007::Precedence.new(:assoc($assoc // "left"), :ops($name => $q));
        }

        if %precedence<tighter> || %precedence<looser> -> $other-op {
            my $pos = @namespace.first(*.contains($other-op), :k);
            $pos += %precedence<tighter> ?? 1 !! 0;
            @namespace.splice($pos, 0, new-prec);
            if $category eq 'prefix' | 'postfix' && $pos <= $!prepostfix-boundary {
                $!prepostfix-boundary++;
            }
        }
        elsif %precedence<equiv> -> $other-op {
            my $prec = @namespace.first(*.contains($other-op));
            die X::Associativity::Conflict.new
                if $assoc !=== Any && $assoc ne $prec.assoc;
            $prec.ops{$name} = $q;
        }
        elsif $category eq 'prefix' {
            @namespace.splice($!prepostfix-boundary++, 0, new-prec);
        }
        else {
            @namespace.push(new-prec);
        }
    }

    method clone {
        my $opl = self.new(
            infixprec => @.infixprec.map(*.clone),
            prepostfixprec => @.prepostfixprec.map(*.clone),
            :$!prepostfix-boundary,
        );
        for <prefix infix postfix> -> $category {
            for %.ops{$category}.kv -> $op, $q {
                $opl.ops{$category}{$op} = $q;
            }
        }
        return $opl;
    }
}
