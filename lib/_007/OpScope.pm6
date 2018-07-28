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

        my $category = ~$0;
        my $op = ~$1;

        if $category eq "infix" | "postfix" {
            my $other_category = $category eq "infix" ?? "postfix" !! "infix";
            die X::Redeclaration.new(:symbol($op))
                if $op eq any(%.ops{$other_category}.keys);
        }

        my %precedence;
        my @prec-traits = <equiv looser tighter>;
        my $assoc;
        for @trait -> $trait {
            my $name = $trait<identifier>.ast.name;
            if $name eq any @prec-traits {
                my $identifier = $trait<EXPR>.ast;
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

        sub prec {
            _007::Precedence.new(:assoc($assoc // "left"), :ops($name => $q));
        }

        my @namespace := $category eq 'infix' ?? @!infixprec !! @!prepostfixprec;
        if %precedence<tighter> || %precedence<looser> -> $other-op {
            my $pos = @namespace.first(*.contains($other-op), :k);
            $pos += %precedence<tighter> ?? 1 !! 0;
            @namespace.splice($pos, 0, prec);
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
