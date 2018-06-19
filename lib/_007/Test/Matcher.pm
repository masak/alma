use _007::Q;

## The Matcher format is a shorthand description of expectations on a Qtree.
#
# The AST format used in the early 007 days was nice because it could very succinctly
# describe a Qtree. Over time it became more intricate and more detailed, and lost
# some of its sweet simplicity. This new matcher format brings that back by making
# every token count.
#
# For example, here's how to match a "hello world" program:
#
#     CompUnit
#         Statement::Expr
#             say(...)
#                 "Hello, world!"
#
# All the Qtypes are referred to without their `Q::` prefix, so `CompUnit`, not
# `Q::CompUnit`.
#
# There are two *short forms* in the above snippet:
#
# * The `say(...)` is actually short for `Postfix [&call, @identifier = say]`. More
#   about the property syntax below.
# * The `"Hello, world!"` is short for `Literal::Str [@value = "Hello, world!"]`.
#   Similar shorthands exist for Int, Bool, and NoneType values.

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
