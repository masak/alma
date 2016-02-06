use v6;
use Test;

sub find($dir, Regex $pattern) {
    my @targets = dir($dir);
    gather while @targets {
        my $file = @targets.shift;
        take $file if $file ~~ $pattern;
        if $file.IO ~~ :d {
            @targets.append: dir($file);
        }
    }
}

my @lib-pms = find("lib", / ".pm" $/)».Str;

my @meta-info-pms =
    qx!perl6 -ne'if /\" \h* \: \h* \" (lib\/_007<-["]>+)/ { say ~$0 }' META.info!.lines;

{
    my $missing-meta-info-lines = (@lib-pms (-) @meta-info-pms).keys.map({ "- $_" }).join("\n");
    is $missing-meta-info-lines, "", "all .pm files in lib/ are declared in META.info";
}

{
    my $superfluous-meta-info-lines = (@meta-info-pms (-) @lib-pms).keys.map({ "- $_" }).join("\n");
    is $superfluous-meta-info-lines, "", "all .pm files declared in META.info also exist in lib/";
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
    }

    from-json(slurp "META.info");
    my $trailing-commas = @trailing-commas.map({ "- $_" }).join("\n");
    is $trailing-commas, "", "there are no trailing commas in the META.info file";
}

done-testing;
