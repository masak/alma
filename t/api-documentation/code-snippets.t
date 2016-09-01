use v6;
use Test;
use _007::Test;

for <lib/_007/Val.pm lib/_007/Q.pm> -> $file {
    my ($topic, @snippet-lines);
    for $file.IO.lines -> $line {
        if $line ~~ /^ \h* '### ### ' (.+) / {  # a heading
            $topic = ~$0;
        }
        elsif $line ~~ /^ \h* '###' ' ' ** 5 (.+) / {  # a code snippet
            my $snippet-line = ~$0;
            @snippet-lines.push($snippet-line);

            my $snippet = @snippet-lines.join("\n");

            if $snippet-line ~~ / '#' \h+ '-->' \h* '`' (<-[`]>*) '`' $/ { # a result line
                my $expected = $0 ~ "\n";
                outputs $snippet, $expected, "[$topic] $snippet-line";
                @snippet-lines.pop;
            }
            elsif $snippet-line ~~ / '#' \h+ '<ERROR' \h+ (<-[>]>+) '>' / { # an expect-error line
                my $type = ::($0);
                runtime-error $snippet, $type, "[$topic] $snippet-line";
                @snippet-lines.pop;
            }
        }
        else {
            @snippet-lines = ();
        }
    }
}

done-testing;
