use _007::Val;
use _007::Q;
use _007::Precedence;

class X::Trait::IllegalValue is Exception {
    has Str $.trait;
    has Str $.value;

    method message { "The value '$.value' is not compatible with the trait '$.trait'" }
}

class X::Trait::Conflict is Exception {
    has Str $.trait1;
    has Str $.trait2;

    method message { "Traits '$.trait1' and '$.trait2' cannot coexist on the same routine" }
}

class X::Precedence::Incompatible is Exception {
    method message { "Trying to relate a pre/postfix operator with an infix operator" }
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

    method maybe-install($identname, @trait) {
        return
            unless $identname ~~ /^ (< prefix infix postfix >)
                                    ':' (.+) /;

        my $type = ~$0;
        my $op = ~$1;

        my %precedence;
        my @prec-traits = <equal looser tighter>;
        my $assoc;
        for @trait -> $trait {
            my $name = $trait<identifier>.ast.name;
            if $name eq any @prec-traits {
                my $identifier = $trait<EXPR>.ast;
                my $prep = $name eq "equal" ?? "to" !! "than";
                die "The thing your op is $name $prep must be an identifier"
                    unless $identifier ~~ Q::Identifier;
                sub check-if-op($s) {
                    die "Unknown thing in '$name' trait"
                        unless $s ~~ /^ < pre in post > 'fix:' /;
                    die X::Precedence::Incompatible.new
                        if $type eq ('prefix' | 'postfix') && $s ~~ /^ in/
                        || $type eq 'infix' && $s ~~ /^ < pre post >/;
                    %precedence{$name} = $s;
                }($identifier.name);
            }
            elsif $name eq "assoc" {
                my $string = $trait<EXPR>.ast;
                die "The associativity must be a string"
                    unless $string ~~ Q::Literal::Str;
                my $value = $string.value.value;
                die X::Trait::IllegalValue.new(:trait<assoc>, :$value)
                    unless $value eq any "left", "non", "right";
                $assoc = $value;
            }
            else {
                die "Unknown trait '$name'";
            }
        }

        if %precedence.keys > 1 {
            my ($t1, $t2) = %precedence.keys.sort;
            die X::Trait::Conflict.new(:$t1, :$t2);
        }

        $*parser.opscope.install($type, $op, :%precedence, :$assoc);
    }

    method install($type, $op, $q?, :%precedence, :$assoc) {
        my $name = "$type:$op";
        my $identifier = Q::Identifier.new(:name(Val::Str.new(:value($name))));

        %!ops{$type}{$op} = $q !=== Any ?? $q !! {
            prefix => Q::Prefix.new(:$identifier),
            infix => Q::Infix.new(:$identifier),
            postfix => Q::Postfix.new(:$identifier),
        }{$type};

        sub prec {
            _007::Precedence.new(:assoc($assoc // "left"), :ops($name => $q));
        }

        my @namespace := $type eq 'infix' ?? @!infixprec !! @!prepostfixprec;
        if %precedence<tighter> || %precedence<looser> -> $other-op {
            my $pos = @namespace.first(*.contains($other-op), :k);
            $pos += %precedence<tighter> ?? 1 !! 0;
            @namespace.splice($pos, 0, prec);
            if $type eq 'prefix' | 'postfix' && $pos <= $!prepostfix-boundary {
                $!prepostfix-boundary++;
            }
        }
        elsif %precedence<equal> -> $other-op {
            my $prec = @namespace.first(*.contains($other-op));
            die X::Associativity::Conflict.new
                if $assoc !=== Any && $assoc ne $prec.assoc;
            $prec.ops{$name} = $q;
        }
        elsif $type eq 'prefix' {
            @namespace.splice($!prepostfix-boundary++, 0, prec);
        }
        else {
            @namespace.push(prec);
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
