use Test;
use _007::Test;

constant MODIFIED_FORMAT_ALMA_FILENAME = "format-$*PID.alma";
LEAVE unlink MODIFIED_FORMAT_ALMA_FILENAME;
my $changed-line = False;

given open(MODIFIED_FORMAT_ALMA_FILENAME, :w) -> $fh {
    for "examples/format.alma".IO.lines -> $line {
        if $line ~~ /^^ '# ' (.+) $$/ {
            $changed-line = True;
            $fh.say: ~$0;
        }
        else {
            $fh.say: $line;
        }
    }
    $fh.close;
}

ok $changed-line, "found a line to un-comment from format.alma";

{
    my @lines = run-and-collect-lines("examples/format.alma");

    is +@lines, 2, "correct number of lines";

    is @lines[0], "abracadabra", "first line";
    is @lines[1], q[foo{1}bar], "second line";
}

{
    my $message = run-and-collect-error-message(MODIFIED_FORMAT_ALMA_FILENAME);

    is $message, "Highest index was 1 but got only 1 arguments.", "got the right error";
}

done-testing;
