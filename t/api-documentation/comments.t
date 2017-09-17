use v6;
use Test;

for <lib/_007/Type.pm> -> $file {
    # I am a state machine. Hello.
    my enum State <Normal ApiComment>;
    my $state = Normal;

    for $file.IO.lines -> $line {
        if $line ~~ /^ "TYPE<" (<-[>]>+) ">" \h* "=" \h* "_007::Type.new(" / {
            ok $state == ApiComment, "$0 is documented";
        }

        my &criterion = $state == Normal
            ?? /^ \h* '###' \h/
            !! /^ \h* '#'/;
        $state = $line ~~ &criterion
            ?? ApiComment
            !! Normal;
    }
}

done-testing;
