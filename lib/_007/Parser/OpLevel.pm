use _007::Parser::Precedence;

class _007::Parser::OpLevel {
    has %.ops =
        prefix => {},
        infix => {},
        postfix => {},
    ;

    has @.infixprec;
    has @.prepostfixprec;
    has $!prepostfix-boundary = 0;

    method install($type, $op, $q?, :%precedence, :$assoc) {
        %!ops{$type}{$op} = $q !=== Any ?? $q !! {
            prefix => Q::Prefix::Custom[$op],
            infix => Q::Infix::Custom[$op],
            postfix => Q::Postfix::Custom[$op],
        }{$type};

        my @namespace := $type eq 'infix' ?? @!infixprec !! @!prepostfixprec;
        sub new-prec() {
            return _007::Parser::Precedence.new(:assoc($assoc // "left"), :ops{ $op => $q });
        }
        if %precedence<tighter> || %precedence<looser> -> $other-op {
            my $pos = @namespace.first(*.contains($other-op), :k);
            $pos += %precedence<tighter> ?? 1 !! 0;
            @namespace.splice($pos, 0, new-prec());
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
            @namespace.splice($!prepostfix-boundary++, 0, new-prec());
        }
        else {
            @namespace.push(new-prec());
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



