use _007::Type;
use _007::Object;
use _007::Precedence;

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
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

    method install($type, $op, $q?, :%precedence, :$assoc) {
        my $name = "$type:$op";
        my $identifier = create(TYPE<Q::Identifier>,
            :name(wrap($name)),
            :frame(NONE),
        );

        %!ops{$type}{$op} = $q !=== Any ?? $q !! {
            prefix => create(TYPE<Q::Prefix>, :$identifier, :operand(NONE)),
            infix => create(TYPE<Q::Infix>, :$identifier, :lhs(NONE), :rhs(NONE)),
            postfix => create(TYPE<Q::Postfix>, :$identifier, :operand(NONE)),
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
