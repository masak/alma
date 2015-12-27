use v6;
use Test;

my @lib-pms =
    qx!find lib/ -name \*.pm!.lines;

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

done-testing;
