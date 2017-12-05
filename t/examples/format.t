use Test;
use _007::Test;

constant MODIFIED_FORMAT_007_FILENAME = "format-$*PID.007";
LEAVE unlink MODIFIED_FORMAT_007_FILENAME;
my $removed-line = False;

given open(MODIFIED_FORMAT_007_FILENAME, :w) -> $fh {
    for "examples/format.007".IO.lines -> $line {
        if $line ~~ /'# throws an exception at compile time' $/ {
            $removed-line = True;
            next;
        }
        $fh.say: $line;
    }
    $fh.close;
}

ok $removed-line, "found a line to remove from format.007";

{
    my @lines = run-and-collect-output(MODIFIED_FORMAT_007_FILENAME);

    is +@lines, 2, "correct number of lines";

    is @lines[0], "abracadabra", "first line";
    is @lines[1], q[foo{1}bar], "second line";
}

{
    my $message = run-and-collect-error-message("examples/format.007");

    is $message, "Highest index was 1 but got only 1 arguments.", "got the right error";
}

done-testing;
