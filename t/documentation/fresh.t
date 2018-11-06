use v6;
use Test;
use _007::Test;

# This test file is behind a feature flag, because it's mostly interesting for developers,
# and requires `pandoc` and `md5sum` to be installed.
ensure-feature-flag("DOCS");

constant $TEMPFILE = 'docs/index-temp.html';

{
    run 'documentation/generate-index-html', $TEMPFILE;
    ok 'docs/index-temp.html'.IO.e, "the file was generated";
    LEAVE unlink $TEMPFILE;

    my $output = qqx"md5sum docs/index.html $TEMPFILE";
    my @lines = $output.lines;
    my $index-md5 = @lines[0].words[0];
    my $tempfile-md5 = @lines[1].words[0];
    is $index-md5, $tempfile-md5, "index.html is up-to-date";
}

done-testing;
