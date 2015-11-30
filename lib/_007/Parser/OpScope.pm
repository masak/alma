use _007::Q;
use _007::Parser::Exceptions;

class _007::Parser::OpScope {
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
            prefix => Q::Prefix["<$op>"],
            infix => Q::Infix["<$op>"],
            postfix => Q::Postfix["<$op>"],
        }{$type};

        my class Precedence {
            has $.assoc = $assoc // "left";
            has %.ops = $op => $q;

            method contains($op) {
                %.ops{$op}:exists;
            }

            method clone {
                self.new(:$.assoc, :%.ops);
            }
        }

        my @namespace := $type eq 'infix' ?? @!infixprec !! @!prepostfixprec;
        if %precedence<tighter> || %precedence<looser> -> $other-op {
            my $pos = @namespace.first(*.contains($other-op), :k);
            $pos += %precedence<tighter> ?? 1 !! 0;
            @namespace.splice($pos, 0, Precedence.new);
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
            @namespace.splice($!prepostfix-boundary++, 0, Precedence.new);
        }
        else {
            @namespace.push(Precedence.new);
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



