use v6;
use Test;
use _007::Test;

my %flags-checked;
for find("lib", / ".pm6" $/) -> $io {
    for $io.lines -> $line {
        if $line ~~ / '{ check-feature-flag("' <-["]>+ '",' \h* '"' (\w+) / {
            my $flag = ~$0;
            %flags-checked{$flag}++;
        }
    }
}

my $content = slurp("feature-flags.json");

{
    is trailing-commas($content), "", "there are no trailing commas in the feature-flags.json file";
}

{
    my %data = from-json($content);

    ok (%data.keys (-) %flags-checked.keys).perl eq "Set.new()", "we're checking all flags we're declaring";
    ok (%flags-checked.keys (-) %data.keys).perl eq "Set.new()", "we're declaring all flags we're checking";

    for %data.kv -> $flag, %props {
        ok %props<issue> ~~ Str, "the 'issues' property exists for '$flag' and is a string";
        ok %props<tests> ~~ Array, "the 'tests' property exists for '$flag' and is an array";
        if %props<tests> ~~ Array {
            for %props<tests> -> $test {
                my $ensures = False;
                for $test.IO.lines -> $line {
                    $ensures ||= $line ~~ /^ 'ensure-feature-flag(' /;
                }
                ok $ensures, "the file '$test' ensures '$flag'";
            }
        }
        ok %props<milestones> ~~ Array, "the 'milestones' property exists for '$flag' and is an array";
        if %props<milestones> ~~ Array {
            ok so(all(%props<milestones>) ~~ Str), "...of strings";
        }
    }
}

done-testing;
