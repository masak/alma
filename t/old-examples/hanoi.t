use Test;
use _007;

my $program = q:to/EOF/;
    my PIN   = "    |    ";

    my DISK = {
        tiny:  "   ===   ",
        small: "  =====  ",
        large: " ======= ",
        huge:  "========="
    };

    my state = [
        [DISK["huge"], DISK["large"], DISK["small"], DISK["tiny"]],
        [],
        []
    ];

    func tw(n, L) {
        if L >= state[n].size() {
            return PIN;
        }
        return state[n][L];
    }

    func show() {
        for (^5).reverse() -> L {
            say(tw(0, L), " ", tw(1, L), " ", tw(2, L));
        }
    }

    func move(diskname, from, to) {
        say();
        say("Moving ", diskname, " from pile ", from + 1, " to pile ", to + 1, "...");
        say();
        my disk = state[from].pop();
        state[to].push(disk);
        show();
    }

    func solveHanoi(n, from, helper, to) {
        if n >= 2 {
            solveHanoi(n - 1, from, to, helper);
        }
        move(["tiny disk", "small disk", "large disk", "huge disk"][n - 1], from, to);
        if n >= 2 {
            solveHanoi(n - 1, helper, from, to);
        }
    }

    show();
    solveHanoi(4, 0, 1, 2);
    EOF

my class LinesOutput {
    has $!result handles <lines> = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

my $output = LinesOutput.new;
given _007.runtime(:input($*IN), :$output) -> $runtime {
    my $ast = _007.parser(:$runtime).parse($program);
    $runtime.run($ast);
}

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
is parse-state($output.lines[^5]).perl, @initial-state.perl, "correct initial state";
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
    last if $move-line-num >= $output.lines;

    my $move = $output.lines[$move-line-num];
    check-move-correctness($move, @state);
    do-move($move);

    my @state-lines = $output.lines[8 * $n .. 8 * $n + 4];
    is parse-state(@state-lines).perl, @state.perl, "state is the expected one after move $n";
}

my @final-state = [], [], ["huge", "large", "small", "tiny"];
is parse-state($output.lines[*-5 .. *-1]).perl, @final-state.perl, "correct final state";

done-testing;
