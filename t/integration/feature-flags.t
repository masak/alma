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

{
    my grammar JSON::Tiny::Grammar {
        token TOP       { ^ \s* [ <object> | <array> ] \s* $ }
        rule object     { '{' ~ '}' <pairlist>     }
        rule pairlist   { <pair> * % \, $<trailing>=[\,]? }
        rule pair       { <string> ':' <value>     }
        rule array      { '[' ~ ']' <arraylist>    }
        rule arraylist  {  <value> * % [ \, ]        }

        proto token value {*};
        token value:sym<number> {
            '-'?
            [ 0 | <[1..9]> <[0..9]>* ]
            [ \. <[0..9]>+ ]?
            [ <[eE]> [\+|\-]? <[0..9]>+ ]?
        }
        token value:sym<true>    { <sym>    };
        token value:sym<false>   { <sym>    };
        token value:sym<null>    { <sym>    };
        token value:sym<object>  { <object> };
        token value:sym<array>   { <array>  };
        token value:sym<string>  { <string> }

        token string {
            \" ~ \" [ <str> | \\ <str=.str_escape> ]*
        }
        token str {
            <-["\\\t\n]>+
        }

        token str_escape {
            <["\\/bfnrt]> | 'u' <utf16_codepoint>+ % '\u'
        }
        token utf16_codepoint {
            <.xdigit>**4
        }
    }

    my @trailing-commas;

    my class JSON::Tiny::Actions {
        has $.text;

        method TOP($/) {
            make $/.values.[0].made;
        };
        method object($/) {
            make $<pairlist>.made.hash.item;
        }

        method pairlist($/) {
            sub linecol($pos) {
                my $line = $.text.substr(0, $pos).comb(/\n/) + 1;
                my $column = $.text.substr(0, $pos).subst(/.* \n/, "").chars + 1;
                return $line, $column;
            }

            if ~$<trailing> {
                my ($line, $column) = linecol($<trailing>.from);
                push @trailing-commas, "Trailing comma at line $line, column $column";
            }
            make $<pair>>>.made.flat;
        }

        method pair($/) {
            make $<string>.made => $<value>.made;
        }

        method array($/) {
            make $<arraylist>.made.item;
        }

        method arraylist($/) {
            make [$<value>.map(*.made)];
        }

        method string($/) {
            make +@$<str> == 1
                ?? $<str>[0].made
                !! $<str>>>.made.join;
        }
        method value:sym<number>($/) { make +$/.Str }
        method value:sym<string>($/) { make $<string>.made }
        method value:sym<true>($/)   { make Bool::True  }
        method value:sym<false>($/)  { make Bool::False }
        method value:sym<null>($/)   { make Any }
        method value:sym<object>($/) { make $<object>.made }
        method value:sym<array>($/)  { make $<array>.made }

        method str($/)               { make ~$/ }

        my %h = '\\' => "\\",
                '/'  => "/",
                'b'  => "\b",
                'n'  => "\n",
                't'  => "\t",
                'f'  => "\f",
                'r'  => "\r",
                '"'  => "\"";
        method str_escape($/) {
            if $<utf16_codepoint> {
                make utf16.new( $<utf16_codepoint>.map({:16(~$_)}) ).decode();
            } else {
                make %h{~$/};
            }
        }
    }

    class X::JSON::Tiny::Invalid is Exception {
        has $.source;
        method message { "Input ($.source.chars() characters) is not a valid JSON string" }
    }

    sub from-json($text) {
        my $actions = JSON::Tiny::Actions.new(:$text);
        my $o = JSON::Tiny::Grammar.parse($text, :$actions);
        unless $o {
            X::JSON::Tiny::Invalid.new(source => $text).throw;
        }
        return $o.ast;
    }

    my %data = from-json(slurp "feature-flags.json");
    my $trailing-commas = @trailing-commas.map({ "- $_" }).join("\n");
    is $trailing-commas, "", "there are no trailing commas in the feature-flags.json file";

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
