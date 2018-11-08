use v6;
use Test;
use _007::Test;

my @lib-pms = find("lib", / ".pm6" $/)».Str;

my @meta-info-pms = "META6.json".IO.lines.map({ ~$0 if /\" \h* \: \h* \" (lib\/_007<-["]>+)/ });

{
    my $missing-meta-info-lines = (@lib-pms (-) @meta-info-pms).keys.map({ "- $_" }).join("\n");
    is $missing-meta-info-lines, "", "all .pm6 files in lib/ are declared in META6.json";
}

{
    my $superfluous-meta-info-lines = (@meta-info-pms (-) @lib-pms).keys.map({ "- $_" }).join("\n");
    is $superfluous-meta-info-lines, "", "all .pm6 files declared in META6.json also exist in lib/";
}

{
    is trailing-commas(slurp "META6.json"), "", "there are no trailing commas in the META6.json file";
}

done-testing;
