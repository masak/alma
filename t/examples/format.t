use Test;
use _007::Test;

constant MODIFIED_FORMAT_007_FILENAME = "format-$*PID.007";
LEAVE unlink MODIFIED_FORMAT_007_FILENAME;
my $changed-line = False;

given open(MODIFIED_FORMAT_007_FILENAME, :w) -> $fh {
    for "examples/format.007".IO.lines -> $line {
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

ok $changed-line, "found a line to un-comment from format.007";

{
    my @lines = run-and-collect-lines("examples/format.007");

    is +@lines, 2, "correct number of lines";

    is @lines[0], "abracadabra", "first line";
    is @lines[1], q[foo{1}bar], "second line";
}

{
    my $message = run-and-collect-error-message(MODIFIED_FORMAT_007_FILENAME);

    is $message, "Highest index was 1 but got only 1 arguments.", "got the right error";
}

done-testing;
