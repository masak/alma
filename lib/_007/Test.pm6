use _007;
use _007::Val;
use _007::Q;
use _007::Parser::Actions;
use _007::Backend::JavaScript;

use Test;

my class StrOutput {
    has $.result = "";

    method flush() {}
    method print($s) { $!result ~= $s.gist }
}

my class UnwantedOutput {
    method flush() { die "Program flushed; was not expected to print anything" }
    method print($s) { die "Program printed '$s'; was not expected to print anything" }
}

sub empty-diff($text1 is copy, $text2 is copy, $desc) {
    s/<!after \n> $/\n/ for $text1, $text2;  # get rid of "no newline" warnings
    spurt("/tmp/t1", $text1);
    spurt("/tmp/t2", $text2);
    my $diff = qx[diff -U2 /tmp/t1 /tmp/t2];
    $diff.=subst(/^\N+\n\N+\n/, '');  # remove uninformative headers
    is $diff, "", $desc;
}

sub parse-error($program, $expected-error, $desc = $expected-error.^name) is export {
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    $parser.parse($program);

    CATCH {
        when $expected-error {
            pass $desc;
        }
        default {
            is .^name, $expected-error.^name, $desc;   # which we know will flunk
            return;
        }
    }
    flunk $desc;
}

sub runtime-error($program, $expected-error, $desc = $expected-error.^name) is export {
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    {
        $runtime.run($ast);

        CATCH {
            when $expected-error {
                pass $desc;
            }
            default {
                is .^name, $expected-error.^name, $desc;   # which we know will flunk
                return;
            }
        }

        is "no error", $expected-error.^name, $desc;
    }
}

sub outputs($program, $expected, $desc = "MISSING TEST DESCRIPTION", :@indata = []) is export {
    class InputFromData {
        has @.indata;
        has $!index = 0;

        method get() {
            return $!index < @.indata
                ?? @.indata[$!index++]
                !! Nil;
        }
    }

    my $input = InputFromData.new(:@indata);
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$input, :$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    is $output.result, $expected, $desc;
}

sub throws-exception($program, $message, $desc = "MISSING TEST DESCRIPTION") is export {
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    CATCH {
        when X::_007::RuntimeException {
            is .message, $message, "passing the right Exception's message";
            pass $desc;
        }
    }

    flunk $desc;
}

sub has-exit-code($program, $expected-exit-code, $desc = "MISSING TEST DESCRIPTION") is export {
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    $runtime.run($ast);

    is $runtime.exit-code, $expected-exit-code, $desc;
}

sub emits-js($program, @expected-builtins, $expected, $desc = "MISSING TEST DESCRIPTION") is export {
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $parser = _007.parser(:$runtime);
    my $ast = $parser.parse($program);
    my $emitted-js = _007::Backend::JavaScript.new.emit($ast);
    my $actual = $emitted-js ~~ /^^ '(() => { // main program' \n ([<!before '})();'> \N+ [\n|$$]]*)/
        ?? (~$0).indent(*)
        !! $emitted-js;
    my @actual-builtins = $emitted-js.comb(/^^ "function " <(<-[(]>+)>/);

    empty-diff @expected-builtins.sort.join("\n"), @actual-builtins.sort.join("\n"), "$desc (builtins)";
    empty-diff $expected, $actual, $desc;
}

sub run-and-collect-output($filepath, :$input = $*IN) is export {
    my $program = slurp($filepath);
    my $output = StrOutput.new;
    my $runtime = _007.runtime(:$input, :$output);
    my $ast = _007.parser(:$runtime).parse($program);
    $runtime.run($ast);

    return $output.result;
}

sub run-and-collect-lines($filepath, :$input) is export {
    return run-and-collect-output($filepath, :$input).lines;
}

sub run-and-collect-error-message($filepath) is export {
    my $program = slurp($filepath);
    my $output = UnwantedOutput.new;
    my $runtime = _007.runtime(:$output);
    my $ast = _007.parser(:$runtime).parse($program);
    $runtime.run($ast);

    CATCH {
        return .message;
    }
}

sub ensure-feature-flag($flag) is export {
    my $envvar = "FLAG_007_{$flag}";
    unless %*ENV{$envvar} {
        skip("$envvar is not enabled", 1);
        done-testing;
        exit 0;
    }
}

sub find($dir, Regex $pattern) is export {
    my @targets = dir($dir);
    my @files;
    while @targets {
        my $file = @targets.shift;
        push @files, $file if $file ~~ $pattern;
        if $file.IO ~~ :d {
            @targets.append: dir($file);
        }
    }
    return @files;
}

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

my class JSON::Tiny::TrailingCommas {
    has $.text;
    has @.trailing-commas;

    method pairlist($/) {
        sub linecol($pos) {
            my $line = $.text.substr(0, $pos).comb(/\n/) + 1;
            my $column = $.text.substr(0, $pos).subst(/.* \n/, "").chars + 1;
            return $line, $column;
        }

        if ~$<trailing> {
            my ($line, $column) = linecol($<trailing>.from);
            push @.trailing-commas, "Trailing comma at line $line, column $column";
        }
    }
}

class X::JSON::Tiny::Invalid is Exception {
    has $.source;
    method message { "Input ($.source.chars() characters) is not a valid JSON string" }
}

sub trailing-commas($text) is export {
    my $actions = JSON::Tiny::TrailingCommas.new(:$text);
    my $o = JSON::Tiny::Grammar.parse($text, :$actions);
    return $actions.trailing-commas.map({ "- $_" }).join("\n");
}

sub from-json($text) is export {
    my $actions = JSON::Tiny::Actions.new(:$text);
    my $o = JSON::Tiny::Grammar.parse($text, :$actions);
    unless $o {
        X::JSON::Tiny::Invalid.new(source => $text).throw;
    }
    return $o.ast;
}

our sub EXPORT(*@things) {
    my %exports;
    for @things -> $thing {
        my $routine = EXPORT::ALL::{$thing} // die "Didn't find '$thing'";
        %exports{$thing} = $routine;
    }
    return %exports;
}
