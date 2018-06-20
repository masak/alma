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
# All the Qtypes are referred to without their `Q::` prefix, so `CompUnit`, not
# `Q::CompUnit`.
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
# There are two *short forms* in the above snippet:
#
# * The `say(...)` is actually short for `Postfix [&call, @operand = say]`. More
#   about the property syntax below.
# * The `"Hello, world!"` is short for `Literal::Str [@value = "Hello, world!"]`.
#   Similar shorthands exist for Int, Bool, and NoneType values.
#
# A `Q::CompUnit` actually contains a `Q::Block` which in turn contains a
# `Q::StatementList` which *then* contains a sequence of statements -- but these
# levels are always there and are thus not of great interest. The format requires
# you to skip mentioning them.
#
# After matching the Qtype itself, you can optionally specify a `[]`-enclosed list
# of properties, that come in two forms:
#
# - Attributes, which are written like `@identifier = say`. The left-hand side starts
#   with a `@` and corresponds to a property on the Qnode being matched. (If the
#   property doesn't exist, an exception is thrown.) More below on what goes on the
#   right-hand side.
#
# - Predicates, which are predefined one-word checks, usually against a small subset
#   of Qtypes or even a single Qtype. For example, the `&call` example above is short
#   for `@identifier = postfix:<()>`. In general, a predicate could check for
#   anything on the Qnode, not just its properties.
#
# There are several possible formats/value types that go on the right side of an
# attribute:
#
# * Identifiers. When we write `@operand = say` above, we mean that the property
#   contains a Q::Identifier whose name is "say".
#
# * Int and Str values similarly denote Q::Literal::Int and Q::Literal::Str values,
#   respectively.

my grammar Matcher::Syntax {
    token TOP { <line>+ }

    token line { ^^ <indent> [<node> | <yadda> | <callsugar>] $$ \n? }

    token indent { " "* }
    token node { <qname> \h* <proplist>? }
    token yadda { "..." }
    token callsugar { (\w+) "(...)" }

    token qname { [\w+]+ % "::" }
    token proplist { "[" ~ "]" [\h* <prop>+ % ["," \h*] \h*] }

    token prop { <predicate> | <attribute> }

    token predicate { "&" \w+ }
    token attribute { "@" (\w+) \h* "=" \h* ([<!before "," | "]"> \S]+) }
}

my class Matcher::MoreChildren {
}

my class PropMatcher::Predicate::Call {
    method matches($qtree) {
        return $qtree ~~ Q::Postfix::Call
            && $qtree.identifier.name.value eq "postfix:()";
    }
}

my class PropMatcher::Attribute {
    has $.name;
    has $.value;

    method matches($qtree) {
        return $qtree."$.name"() eq $.value;
    }
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

        my $matcher = $<node>.ast || $<yadda>.ast || $<callsugar>.ast;
        make $matcher;

        if @!stack.elems > 0 {
            my $parent = @!stack[*-1];
            $parent.childmatchers.push($matcher);
        }

        @!stack.push($matcher);
    }

    method node($/) {
        my $qname = $<qname>.Str;
        die "Shouldn't write out the Q:: since it's implicit: '{$qname}'"
            if $qname.substr(0, 3) eq "Q::";

        my $qtype = ::("Q::{$qname}");
        my @proplist = $<proplist>.ast || [];

        make Matcher.bless(:$qtype, :@proplist);
    }

    method yadda($/) {
        die "Can't have a '...' on indentation level 0"
            if @!stack.elems == 0;

        my $parent = @!stack[*-1];
        $parent.more-children = True;

        make Matcher::MoreChildren.new();
    }

    method callsugar($/) {
        my $value = ~$0;
        my $qtype = Q::Postfix;
        my @proplist =
            PropMatcher::Predicate::Call.new(),
            PropMatcher::Attribute.new(
                :name("operand"),
                :$value,
            );

        make Matcher.bless(:$qtype, :@proplist);
    }

    method proplist($/) {
        make $<prop>.map(*.ast);
    }

    method prop($/) {
        make $<predicate>.ast || $<attribute>.ast;
    }

    method predicate($/) {
        my $name = $/.Str;
        die "Unknown predicate '{$name}'"
            unless $name eq "&call";

        make PropMatcher::Predicate::Call.new();
    }

    method attribute($/) {
        my $name = $0.Str;
        my $value = $1.Str;

        make PropMatcher::Attribute.new(:$name, :$value);
    }
}

sub is-empty($qtree) {
    return kids($qtree).elems == 0;
}

sub kids($qtree, Bool :$call) {
    if $call {  # then it's a Q::Postfix::Call, and we want to return its arguments
        return $qtree.argumentlist.arguments.elements;
    }

    given $qtree {
        when Q::CompUnit {
            return $qtree.block.statementlist.statements.elements;
        }
        when Q::Postfix {
            die "Can't check children of Q::Postfix";
        }
        default {
            die "Unrecognized qtype: {$qtree.^name}";
        }
    }
}

class Matcher {
    has Q $.qtype is rw;
    has @.proplist;
    has @.childmatchers;
    has $.more-children is rw = False;

    method new($description) {
        my $actions = Matcher::Actions.new();
        my $m = Matcher::Syntax.parse($description, :$actions)
            or die "Couldn't parse:\n\n{$description.indent(4)}";
        return $m.ast;
    }

    method matches(Q $qtree) {
        my $call = so any @.proplist »~~» PropMatcher::Predicate::Call;
        return $qtree ~~ $.qtype
            && ($.more-children
                ?? kids($qtree, :$call) >= @.childmatchers
                !! kids($qtree, :$call) == @.childmatchers);
    }
}
