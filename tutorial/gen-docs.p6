use v6;

my $docs;
for <lib/_007/Val.pm lib/_007/Q.pm> -> $file {
    for $file.IO.lines -> $line {
        if $line ~~ /^ \h* '### ### ' (.+) / {  # a heading
            $docs ~= "\n";
        }

        if $line ~~ /^ \h* '### ' (.+)/ {
            $docs ~= "\n";
            $docs ~= $0;
        }
        elsif $line ~~ /^ \h* '###' $/ {
            $docs ~= "\n";
        }
    }

    $docs ~= "\n\n";
}

my $md-file = "tutorial/DOCS.md";
my $output-file = "tutorial/docs.html";
spurt($md-file, $docs);

my $header = q:to/HEADER/;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>007 tutorial</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
    <style>
      .perl6-feature { background: #ddf; }
      .python-feature { background: #dfd; }
    </style>
  </head>
  <body>
<a href="https://github.com/masak/007"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://camo.githubusercontent.com/652c5b9acfaddf3a9c326fa6bde407b87f7be0f4/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f6f72616e67655f6666373630302e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png"></a>
<div class="container">
HEADER

my $footer = q:to/FOOTER/;
</div>
  </body>
</html>
FOOTER

spurt($output-file, $header);
shell("pandoc -f markdown -t html5 $md-file >> $output-file");
shell("echo '$footer' >> $output-file");
