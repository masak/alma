use Test;

my $output = qx[perl6 bin/007 examples/hanoi.007];
my @lines = lines($output);

sub parse-state(@lines) {
    my @state = [], [], [];

    for @lines.reverse -> $line {
        for 0..2 -> $column {
            given $line.substr(10 * $column, 9) {
                when "    |    " { succeed }
                when "   ===   " { push @state[$column], "tiny" }
                when "  =====  " { push @state[$column], "small" }
                when " ======= " { push @state[$column], "large" }
                when "=========" { push @state[$column], "huge" }
                default { die "Unrecognized input '$_'" }
            }
        }
    }

    return @state;
}

sub check-move-correctness($line, @state) {
    sub size($_) {
        when "tiny" { 1 }
        when "small" { 2 }
        when "large" { 3 }
        when "huge" { 4 }
        default { die "Unrecognized disk size '$_'" }
    }

    my $correct-format = so $line ~~ /^ "Moving " (\w+) " disk from pile " (\d) " to pile " (\d) "..." $/;
    ok $correct-format, "the move is of a recognized format";
    exit unless $correct-format;

    my $disk = ~$0;
    my $from = +$1;
    my $to = +$2;
    my $disk-in-frompile = @state[$from - 1] > 0;
    ok $disk-in-frompile, "there is at least one disk in the from pile";
    exit unless $disk-in-frompile;

    my @topile = @state[$to - 1].list;
    my $disk-placement-legal = @topile == 0 || size(@topile[*-1]) > size($disk);
    ok $disk-placement-legal, "legal disk placement: on empty pile or bigger disk";
    exit unless $disk-placement-legal;
}

my @initial-state = ["huge", "large", "small", "tiny"], [], [];
is parse-state(@lines[^5]).perl, @initial-state.perl, "correct initial state";
my @state = @initial-state;

sub do-move($line) {
    $line ~~ /^ "Moving " (\w+) " disk from pile " (\d) " to pile " (\d) "..." $/;
    my $from = +$1;
    my $to = +$2;

    my $disk = @state[$from - 1].pop;
    @state[$to - 1].push($disk);
}

for 1..Inf -> $n {
    my $move-line-num = 8 * $n - 2;
    last if $move-line-num >= @lines;

    my $move = @lines[$move-line-num];
    check-move-correctness($move, @state);
    do-move($move);

    my @state-lines = @lines[8 * $n .. 8 * $n + 4];
    is parse-state(@state-lines).perl, @state.perl, "state is the expected one after move $n";
}

my @final-state = [], [], ["huge", "large", "small", "tiny"];
is parse-state(@lines[*-5 .. *-1]).perl, @final-state.perl, "correct final state";

done-testing;
