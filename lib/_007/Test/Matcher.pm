use _007::Q;

my grammar Matcher::Syntax {
    regex TOP { <line>+ }

    regex line { ^^ <indent> <qname> \h* <proplist>? $$ \n? }

    regex indent { \h* }
    regex qname { [\w+]+ % "::" }
    regex proplist { "[" ~ "]" <prop>+ % ["," \h*] }

    regex prop { "&empty" }
}

my class PropMatcher::Empty::CompUnit {
    method matches(Q::CompUnit $compunit) {
        return $compunit.block.statementlist.statements.elements.elems == 0;
    }
}

class Matcher { ... }

my class Matcher::Actions {
    method TOP($/) {
        make $<line>[0].ast;
    }

    method line($/) {
        my $qname = $<qname>.Str;
        my $qtype = ::("Q::{$qname}");
        my @propmatchers = $<proplist>.ast;

        make Matcher.bless(:$qtype, :@propmatchers);
    }

    method proplist($/) {
        make $<prop>.map(*.ast);
    }

    method prop($/) {
        make PropMatcher::Empty::CompUnit.new();
    }
}

class Matcher {
    has Q $.qtype is rw;
    has @.propmatchers;

    method new($description) {
        my $actions = Matcher::Actions.new();
        my $m = Matcher::Syntax.parse($description, :$actions)
            or die "Couldn't parse:\n\n{$description.indent(4)}";
        return $m.ast;
    }

    method matches(Q $qtree) {
        return $qtree ~~ $.qtype
            && ?all(@.propmatchers.map(*.matches($qtree)));
    }
}
