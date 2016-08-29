use _007::Q;
use _007::Precedence;

class _007::OpScope {
    has %.ops =
        prefix => {},
        infix => {},
        postfix => {},
    ;

    has @.infixprec;
    has @.prepostfixprec;
    has $!prepostfix-boundary = 0;

    method install($type, $op, $q?, :%precedence, :$assoc) {
        my $identifier = Q::Identifier.new(:name(Val::Str.new(:value($type ~ ":<$op>"))));

        %!ops{$type}{$op} = $q !=== Any ?? $q !! {
            prefix => Q::Prefix.new(:$identifier),
            infix => Q::Infix.new(:$identifier),
            postfix => Q::Postfix.new(:$identifier),
        }{$type};

        sub prec {
            _007::Precedence.new(:assoc($assoc // "left"), :ops($op => $q));
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
            $prec.ops{$op} = $q;
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
