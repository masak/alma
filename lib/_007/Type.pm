sub unique-id is export { ++$ }

constant TYPE = hash();

class _007::Type {
    has Str $.name;
    has $.base = TYPE<Object>;
    has @.fields;
    has Bool $.is-abstract = False;
    # XXX: $.id

    method install-base($none) {
        $!base = $none;
    }

    method type-chain() {
        my @chain;
        my $t = self;
        while $t ~~ _007::Type {
            @chain.push($t);
            $t.=base;
        }
        return @chain;
    }

    method attributes { () }

    method quoted-Str { self.Str }
    method Str {
        my %*stringification-seen;
        str-helper(self);
    }
}

BEGIN {
    for <Object Type NoneType Bool> -> $name {
        TYPE{$name} = _007::Type.new(:$name);
    }
}
for <Int Str Array Dict> -> $name {
    TYPE{$name} = _007::Type.new(:$name);
}
TYPE<Exception> = _007::Type.new(:name<Exception>, :fields["message"]);
TYPE<Sub> = _007::Type.new(:name<Sub>, :fields["name", "parameterlist", "statementlist", "static-lexpad", "outer-frame"]);
TYPE<Macro> = _007::Type.new(:name<Macro>, :base(TYPE<Sub>));
TYPE<Regex> = _007::Type.new(:name<Regex>, :fields["contents"]);

TYPE<Q> = _007::Type.new(:name<Q>, :is-abstract);
TYPE<Q::Literal> = _007::Type.new(:name<Q::Literal>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Literal::None> = _007::Type.new(:name<Q::Literal::None>, :base(TYPE<Q::Literal>));
TYPE<Q::Literal::Bool> = _007::Type.new(:name<Q::Literal::Bool>, :base(TYPE<Q::Literal>), :fields["value"]);
TYPE<Q::Literal::Int> = _007::Type.new(:name<Q::Literal::Int>, :base(TYPE<Q::Literal>), :fields["value"]);
TYPE<Q::Literal::Str> = _007::Type.new(:name<Q::Literal::Str>, :base(TYPE<Q::Literal>), :fields["value"]);
TYPE<Q::Term> = _007::Type.new(:name<Q::Term>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Term::Dict> = _007::Type.new(:name<Q::Term::Dict>, :base(TYPE<Q::Term>), :fields["propertylist"]);
TYPE<Q::Term::Object> = _007::Type.new(:name<Q::Term::Object>, :base(TYPE<Q::Term>), :fields["type", "propertylist"]);
TYPE<Q::Term::Sub> = _007::Type.new(:name<Q::Term::Sub>, :base(TYPE<Q::Term>), :fields["identifier", "traitlist", "block"]);
TYPE<Q::Term::Quasi> = _007::Type.new(:name<Q::Term::Quasi>, :base(TYPE<Q::Term>), :fields["qtype", "contents"]);
TYPE<Q::Term::Array> = _007::Type.new(:name<Q::Term::Array>, :base(TYPE<Q::Term>), :fields["elements"]);
TYPE<Q::Term::Regex> = _007::Type.new(:name<Q::Term::Regex>, :base(TYPE<Q::Term>), :fields["contents"]);
TYPE<Q::Identifier> = _007::Type.new(:name<Q::Identifier>, :base(TYPE<Q>), :fields["name", "frame"]);
TYPE<Q::Block> = _007::Type.new(:name<Q::Block>, :base(TYPE<Q>), :fields["parameterlist", "statementlist", "static-lexpad"]);
TYPE<Q::Expr> = _007::Type.new(:name<Q::Expr>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Prefix> = _007::Type.new(:name<Q::Prefix>, :base(TYPE<Q::Expr>), :fields["identifier", "operand"]);
TYPE<Q::Prefix::Str> = _007::Type.new(:name<Q::Prefix::Str>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Plus> = _007::Type.new(:name<Q::Prefix::Plus>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Minus> = _007::Type.new(:name<Q::Prefix::Minus>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::So> = _007::Type.new(:name<Q::Prefix::So>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Not> = _007::Type.new(:name<Q::Prefix::Not>, :base(TYPE<Q::Prefix>));
TYPE<Q::Prefix::Upto> = _007::Type.new(:name<Q::Prefix::Upto>, :base(TYPE<Q::Prefix>));
TYPE<Q::Infix> = _007::Type.new(:name<Q::Infix>, :base(TYPE<Q::Expr>), :fields["identifier", "lhs", "rhs"]);
TYPE<Q::Infix::Addition> = _007::Type.new(:name<Q::Infix::Addition>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Subtraction> = _007::Type.new(:name<Q::Infix::Subtraction>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Multiplication> = _007::Type.new(:name<Q::Infix::Multiplication>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Modulo> = _007::Type.new(:name<Q::Infix::Modulo>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Divisibility> = _007::Type.new(:name<Q::Infix::Divisibility>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Concat> = _007::Type.new(:name<Q::Infix::Concat>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Replicate> = _007::Type.new(:name<Q::Infix::Replicate>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::ArrayReplicate> = _007::Type.new(:name<Q::Infix::ArrayReplicate>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Cons> = _007::Type.new(:name<Q::Infix::Cons>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Assignment> = _007::Type.new(:name<Q::Infix::Assignment>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Eq> = _007::Type.new(:name<Q::Infix::Eq>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Ne> = _007::Type.new(:name<Q::Infix::Ne>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Gt> = _007::Type.new(:name<Q::Infix::Gt>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Lt> = _007::Type.new(:name<Q::Infix::Lt>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Ge> = _007::Type.new(:name<Q::Infix::Ge>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Le> = _007::Type.new(:name<Q::Infix::Le>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::Or> = _007::Type.new(:name<Q::Infix::Or>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::DefinedOr> = _007::Type.new(:name<Q::Infix::DefinedOr>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::And> = _007::Type.new(:name<Q::Infix::And>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::TypeMatch> = _007::Type.new(:name<Q::Infix::TypeMatch>, :base(TYPE<Q::Infix>));
TYPE<Q::Infix::TypeNonMatch> = _007::Type.new(:name<Q::Infix::TypeNonMatch>, :base(TYPE<Q::Infix>));
TYPE<Q::Postfix> = _007::Type.new(:name<Q::Postfix>, :base(TYPE<Q::Expr>), :fields["identifier", "operand"]);
TYPE<Q::Postfix::Index> = _007::Type.new(:name<Q::Postfix::Index>, :base(TYPE<Q::Postfix>), :fields["index"]);
TYPE<Q::Postfix::Call> = _007::Type.new(:name<Q::Postfix::Call>, :base(TYPE<Q::Postfix>), :fields["argumentlist"]);
TYPE<Q::Postfix::Property> = _007::Type.new(:name<Q::Postfix::Property>, :base(TYPE<Q::Postfix>), :fields["property"]);
TYPE<Q::Unquote> = _007::Type.new(:name<Q::Unquote>, :base(TYPE<Q>), :fields["qtype", "expr"]);
TYPE<Q::Unquote::Prefix> = _007::Type.new(:name<Q::Unquote::Prefix>, :base(TYPE<Q::Unquote>), :fields["operand"]);
TYPE<Q::Unquote::Infix> = _007::Type.new(:name<Q::Unquote::Infix>, :base(TYPE<Q::Unquote>), :fields["lhs", "rhs"]);
TYPE<Q::Statement> = _007::Type.new(:name<Q::Statement>, :base(TYPE<Q>), :is-abstract);
TYPE<Q::Statement::My> = _007::Type.new(:name<Q::Statement::My>, :base(TYPE<Q::Statement>), :fields["identifier", "expr"]);
TYPE<Q::Statement::Constant> = _007::Type.new(:name<Q::Statement::Constant>, :base(TYPE<Q::Statement>), :fields["identifier", "expr"]);
TYPE<Q::Statement::Block> = _007::Type.new(:name<Q::Statement::Block>, :base(TYPE<Q::Statement>), :fields["block"]);
TYPE<Q::Statement::Throw> = _007::Type.new(:name<Q::Statement::Throw>, :base(TYPE<Q::Statement>), :fields["expr"]);
TYPE<Q::Statement::Sub> = _007::Type.new(:name<Q::Statement::Sub>, :base(TYPE<Q::Statement>), :fields["identifier", "traitlist", "block"]);
TYPE<Q::Statement::Macro> = _007::Type.new(:name<Q::Statement::Macro>, :base(TYPE<Q::Statement>), :fields["identifier", "traitlist", "block"]);
TYPE<Q::Statement::BEGIN> = _007::Type.new(:name<Q::Statement::BEGIN>, :base(TYPE<Q::Statement>), :fields["block"]);
TYPE<Q::Statement::Class> = _007::Type.new(:name<Q::Statement::Class>, :base(TYPE<Q::Statement>), :fields["block"]);
TYPE<Q::CompUnit> = _007::Type.new(:name<Q::CompUnit>, :base(TYPE<Q::Statement::Block>));
TYPE<Q::Statement::Return> = _007::Type.new(:name<Q::Statement::Return>, :base(TYPE<Q::Statement>), :fields["expr"]);
TYPE<Q::Statement::Expr> = _007::Type.new(:name<Q::Statement::Expr>, :base(TYPE<Q::Statement>), :fields["expr"]);
TYPE<Q::Statement::If> = _007::Type.new(:name<Q::Statement::If>, :base(TYPE<Q::Statement>), :fields["expr", "block", "else"]);
TYPE<Q::Statement::For> = _007::Type.new(:name<Q::Statement::For>, :base(TYPE<Q::Statement>), :fields["expr", "block"]);
TYPE<Q::Statement::While> = _007::Type.new(:name<Q::Statement::While>, :base(TYPE<Q::Statement>), :fields["expr", "block"]);
TYPE<Q::StatementList> = _007::Type.new(:name<Q::StatementList>, :base(TYPE<Q>), :fields["statements"]);
TYPE<Q::ArgumentList> = _007::Type.new(:name<Q::ArgumentList>, :base(TYPE<Q>), :fields["arguments"]);
TYPE<Q::Parameter> = _007::Type.new(:name<Q::Parameter>, :base(TYPE<Q>), :fields["identifier"]);
TYPE<Q::ParameterList> = _007::Type.new(:name<Q::ParameterList>, :base(TYPE<Q>), :fields["parameters"]);
TYPE<Q::Property> = _007::Type.new(:name<Q::Property>, :base(TYPE<Q>), :fields["key", "value"]);
TYPE<Q::PropertyList> = _007::Type.new(:name<Q::PropertyList>, :base(TYPE<Q>), :fields["properties"]);
TYPE<Q::Trait> = _007::Type.new(:name<Q::Trait>, :base(TYPE<Q>), :fields["identifier", "expr"]);
TYPE<Q::TraitList> = _007::Type.new(:name<Q::TraitList>, :base(TYPE<Q>), :fields["traits"]);
TYPE<Q::Expr::StatementListAdapter> = _007::Type.new(:name<Q::Expr::StatementListAdapter>, :base(TYPE<Q::Expr>), :fields["statementlist"]);

sub escaped($name) {
    sub escape-backslashes($s) { $s.subst(/\\/, "\\\\", :g) }
    sub escape-less-thans($s) { $s.subst(/"<"/, "\\<", :g) }

    return $name
        unless $name ~~ /^ (prefix | infix | postfix) ':' (.+) /;

    return "{$0}:<{escape-less-thans escape-backslashes $1}>"
        if $1.contains(">") && $1.contains("»");

    return "{$0}:«{escape-backslashes $1}»"
        if $1.contains(">");

    return "{$0}:<{escape-backslashes $1}>";
}

sub pretty($parameterlist) {
    return sprintf "(%s)", $parameterlist.properties<parameters>.value.map({
        .properties<identifier>.properties<name>
    }).join(", ");
}

our sub str-helper($_) is export {
    when _007::Type { "<type {.name}>" }
    when .type === TYPE<NoneType> | TYPE<Bool> { .name }
    when .type === TYPE<Array> { .quoted-Str }
    when .type === TYPE<Dict> { .quoted-Str }
    when .type === TYPE<Exception> { "Exception \{message: {.properties<message>.quoted-Str}\}" }
    when .type === TYPE<Sub> {
        sprintf "<sub %s%s>", escaped(.properties<name>.value), pretty(.properties<parameterlist>)
    }
    when .type === TYPE<Macro> {
        sprintf "<macro %s%s>", escaped(.properties<name>.value), pretty(.properties<parameterlist>)
    }
    when .type === TYPE<Regex> {
        "/" ~ .contents.quoted-Str ~ "/"
    }
    when .isa("Q") {
        my $self = $_;
        my @props = $self.type.type-chain.reverse.map({ .fields }).flat;
        # XXX: thuggish way to hide things that weren't listed in `attributes` before
        @props.=grep: {
            !($self.isa("Q::Identifier") && $_ eq "frame") &&
            !($self.isa("Q::Block") && $_ eq "static-lexpad")
        };
        if @props == 1 {
            return "{$self.type.name} { $self.properties{@props[0]}.quoted-Str }";
        }
        sub keyvalue($prop) { $prop ~ ": " ~ $self.properties{$prop}.quoted-Str }
        my $contents = @props.map(&keyvalue).join(",\n").indent(4);
        return "{$self.type.name} \{\n$contents\n\}";
    }
    when .^name eq "_007::Object::Wrapped" { .value.Str }
    default { die "Unexpected type ", .^name }
}
