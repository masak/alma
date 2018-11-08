use v6;
use Test;

{
    my $input-checksum = qqx"md5sum documentation/README.md".substr(0, 6);

    my $output-checksum;
    for "docs/index.html".IO.lines -> $line {
        next unless $line ~~ / 'class="checksum-' (<[ 0..9 a..f ]>+) /;
        $output-checksum = ~$0;
    }

    ok defined($output-checksum), "found a checksum";
    is $output-checksum, $input-checksum, "output is generated off of latest input";
}

done-testing;
