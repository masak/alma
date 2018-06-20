use _007::Q;

## The Matcher format is a shorthand description of expectations on a Qtree.
#
# The AST format used in the early 007 days was nice because it could very succinctly
# describe a Qtree. Over time it became more intricate and more detailed, and lost
# some of its sweet simplicity. This new matcher format brings that back by making
# every token count.
#
# For example, here's how to match an empty program:
#
#     CompUnit
#
# Besides matching the qtree as a `Q::CompUnit`, the absence of child nodes is used
# to *assert* that the `Q::CompUnit` has an empty statement list.
#
# Here, on the other hand, is how to match a non-empty program:
#
#     CompUnit
#         ...
#
# The `...` syntax means "at least one (more) child node here". It can only be used
# at a nonzero indent level.
#
# A "hello world" program:
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

    regex line { ^^ <indent> [<node> | <yadda>] $$ \n? }

    regex indent { " "* }
    regex node { <qname> \h* <proplist>? }
    regex yadda { "..." }

    regex qname { [\w+]+ % "::" }
    regex proplist { "[" ~ "]" <prop>+ % ["," \h*] }
}

my class Matcher::MoreChildren {
}

class Matcher { ... }

my class Matcher::Actions {
    has @!stack;

    method TOP($/) {
        make $<line>[0].ast;
    }

    method line($/) {
        my $indent = $<indent>.chars;
        die "Indent needs to be a multiple of 4 (but is {$indent})"
            unless $indent %% 4;

        my $indent-level = $indent / 4;
        die "Too much indent -- was level {$indent-level} but could be at most {@.stack.elems + 1}"
            if $indent-level > @!stack.elems + 1;

        @!stack.pop while @!stack.elems > $indent-level;

        my $matcher = $<node>.ast || $<yadda>.ast;
        make $matcher;

        if @!stack.elems > 0 {
            my $parent = @!stack[*-1];
            $parent.childmatchers.push($matcher);
        }

        @!stack.push($matcher);
    }

    method node($/) {
        my $qname = $<qname>.Str;
        my $qtype = ::("Q::{$qname}");

        make Matcher.bless(:$qtype);
    }

    method yadda($/) {
        die "Can't have a '...' on indentation level 0"
            if @!stack.elems == 0;

        my $parent = @!stack[*-1];
        $parent.more-children = True;

        make Matcher::MoreChildren.new();
    }

    method proplist($/) {
        make $<prop>.map(*.ast);
    }

    method prop($/) {
        die "Not handling props yet";
    }
}

sub is-empty($qtree) {
    die "Unrecognized qtype: {$qtree.^name}"
        unless $qtree ~~ Q::CompUnit;

    return $qtree.block.statementlist.statements.elements.elems == 0;
}

class Matcher {
    has Q $.qtype is rw;
    has @.childmatchers;
    has $.more-children is rw = False;

    method new($description) {
        my $actions = Matcher::Actions.new();
        my $m = Matcher::Syntax.parse($description, :$actions)
            or die "Couldn't parse:\n\n{$description.indent(4)}";
        return $m.ast;
    }

    method matches(Q $qtree) {
        return $qtree ~~ $.qtype
            && ($.more-children ^^ is-empty($qtree));
    }
}
