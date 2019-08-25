use v6;
use Test;

for <lib/Alma/Val.pm6 lib/Alma/Q.pm6> -> $file {
    # I am a state machine. Hello.
    my enum State <Normal ApiComment>;
    my $state = Normal;

    for $file.IO.lines -> $line {
        next if $line ~~ / \h '{ ... }' $/;

        if $line ~~ /^ < class role > \h+ (Q | < Val:: Q:: > \S+)/ {
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
