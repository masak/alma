use v6;
use Test;
use _007::Test;

for <lib/_007/Val.pm lib/_007/Q.pm> -> $file {
    my $code;
    my $result;

    for $file.IO.lines -> $line {
        if $line ~~ /^ \h* '###' ' ' ** 5 (.+) / {

            my $c = ~$0;
            if $c ~~ / \h* '`' (<-[`]>*) '`' $/ {
                $result = ~$0;
            }
            $code ~= $c;

            if $result {
                outputs $code, $result ~ "\n", $code;
                
                $code = '';
                $result = '';
            }
            else {
                $code ~= "\n";
            }
        }
    }
}

done-testing;
