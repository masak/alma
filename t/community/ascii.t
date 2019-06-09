use Test;
use _007;
use _007::Test;

plan 5;

my $path = "t/community/code/ascii.007";
my $program = slurp($path);

my $inserted-code = q:to 'EOC';
    BEGIN my actualSay = say;
    my captureOutput = false;
    my output = "";
    my NL = 10.chr();
    my n = 1;       # at this point, we've already run one test in Perl 6

    func say(string) {
        if captureOutput {
            output = output ~ string ~ NL;
        }
        else {
            actualSay(string);
        }
    }

    func ok(cond, description) {
        my status = "NOT OK";
        if cond {
            status = "ok";
        }
        n = n + 1;
        actualSay(status, " ", n, " - ", description);
    }

    func is(actual, expected, description) {
        my cond = actual == expected;
        ok(cond, description);
        if !cond {
            actualSay("Actual:   ", actual);
            actualSay("Expected: ", expected);
        }
    }

    {
        my criterion = true;
        for charLookup.keys() -> key {
            my char = charLookup[key];
            criterion = criterion && char.size() == 7;
        }
        ok(criterion, "all characters are 7 lines tall");
    }

    {
        my criterion = true;
        for charLookup.keys() -> key {
            my char = charLookup[key];
            my width = char[0].chars();
            for char -> line {
                criterion = criterion && line.chars() == width;
            }
        }
        ok(criterion, "each character is of uniform width");
    }

    {
        output = "";
        {
            captureOutput = true;
            printHeader("");
            captureOutput = false;
        }
        my sevenNls = NL ~ NL ~ NL ~ NL ~ NL ~ NL ~ NL;

        is(output, sevenNls, "printHeader on empty string prints 7 empty lines");
    }

    {
        output = "";
        {
            captureOutput = true;
            printHeader("GREETINGS");
            captureOutput = false;
        }
        my expectedOutput = [
            " e88~~\    888~-_     888~~    888~~    ~~~888~~~   888   888b    |    e88~~\    ,d88~~\    ",
            "d888       888   \    888___   888___      888      888   |Y88b   |   d888       8888       ",
            "8888 __    888    |   888      888         888      888   | Y88b  |   8888 __     Y88b      ",
            "8888   |   888   /    888      888         888      888   |  Y88b |   8888   |     Y88b,    ",
            "Y888   |   888_-~     888      888         888      888   |   Y88b|   Y888   |      8888    ",
            " 88___/    888 ~-_    888___   888___      888      888   |    Y888    88___/    \__88P     ",
            "                                                                                            ",
        ].join(NL) ~ NL;

        is(output, expectedOutput, "printHeader on a greeting prints the expected output");
    }
    EOC

my $modified-program = $program.subst(/'func MAIN() {' \n ['    ' \N+ \n | \h* \n]+ '}' \n/, $inserted-code);
ok $program ne $modified-program, "successfully injected the testing code";

my $ast = _007.parser.parse($modified-program);
_007.runtime.run($ast);
