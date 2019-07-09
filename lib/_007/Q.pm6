use _007::Val;
use _007::Value;

class X::Control::Return is Exception {
    has $.frame;
    has $.value;
}

class X::Subscript::TooLarge is Exception {
    has $.value;
    has $.length;

    method message() { "Subscript ($.value) too large (array length $.length)" }
}

class X::Subscript::NonInteger is Exception {
}

class X::Subscript::NonString is Exception {
}

class X::ParameterMismatch is Exception {
    has $.type;
    has $.paramcount;
    has $.argcount;

    method message {
        "$.type with $.paramcount parameters called with $.argcount arguments"
    }
}

class X::Property::NotFound is Exception {
    has $.propname;
    has $.type;

    method message {
        "Property '$.propname' not found on object of type $.type"
    }
}

class X::Associativity::Conflict is Exception {
    method message { "The operator already has a defined associativity" }
}

class X::Regex::InvalidMatchType is Exception {
    method message { "A regex can only match strings" }
}

class X::TypeCheck::HeterogeneousArray is Exception {
    has $.operation;
    has $.types;

    method message {
        "Can't do '$.operation' on heterogeneous array, types found: {$.types.sort}"
    }
}

class X::_007::RuntimeException is Exception {
    has $.msg;

    method message {
        $.msg.Str;
    }
}

sub aname($attr) { $attr.name.substr(2) }

### ### Q
###
### An program element; anything that forms a node in the syntax tree
### representing a program.
###
role Q {
    method Str {
        my %*stringification-seen;
        Helper::Str(self);
    }

    method quoted-Str {
        self.Str
    }

    method truthy {
        True
    }

    method attributes {
        sub find($aname) { self.^attributes.first({ $aname eq aname($_) }) }

        self.can("attribute-order")
            ?? self.attribute-order.map({ find($_) })
            !! self.^attributes;
    }
}

### ### Q::Identifier
###
### An identifier; a name in code.
###
class Q::Identifier does Q {
    has _007::Value $.name where &is-str;

    method attribute-order { <name> }
}

### ### Q::Expr
###
### An expression; something that can be evaluated to a value.
###
role Q::Expr does Q {
}

### ### Q::Term
###
### A term; a unit of parsing describing a value or an identifier. Along with
### operators, what makes up expressions.
###
role Q::Term does Q::Expr {
}

### ### Q::Literal
###
### A literal; a constant value written out explicitly in the program, such as
### `none`, `true`, `5`, or `"James Bond"`.
###
### Compound values such as arrays and objects are considered terms but not
### literals.
###
role Q::Literal does Q::Term {
}

### ### Q::Literal::Int
###
### An integer literal; a non-negative number.
###
### Negative numbers are not themselves considered integer literals: something
### like `-5` is parsed as a `prefix:<->` containing a literal `5`.
###
class Q::Literal::Int does Q::Literal {
    has _007::Value $.value where &is-int;
}

### ### Q::Literal::Str
###
### A string literal.
###
class Q::Literal::Str does Q::Literal {
    has _007::Value $.value when &is-str;
}

### ### Q::Term::Identifier
###
### An identifier; a name which identifies a storage location in the program.
###
### Identifiers in expressions are subject to *scoping*: the same name can
### point to different storage locations because they belong to different scopes.
### The same name in the same scope might even point to different storage
### locations at different times when accessed from different call frames.
###
class Q::Term::Identifier is Q::Identifier does Q::Term {
}

### ### Q::Term::Identifier::Direct
###
### A direct identifier; a name which directly identifies a storage location
### in the program.
###
class Q::Term::Identifier::Direct is Q::Term::Identifier {
    has _007::Value $.frame where &is-dict;
}

### ### Q::Regex::Fragment
###
### The parent role to all regex fragment types.
###
role Q::Regex::Fragment {
}

### ### Q::Regex::Str
###
### A regex fragment for a simple string.
### Corresponds to the `"..."` regex syntax.
###
class Q::Regex::Str does Q::Regex::Fragment {
    has _007::Value $.contents where &is-str;
}

### ### Q::Regex::Identifier
###
### A regex fragment using a variable from the program.
### Corresponds to an identifier in a regex.
###
class Q::Regex::Identifier does Q::Regex::Fragment {
    has Q::Identifier $.identifier;
}

### ### Q::Regex::Call
###
### A regex fragment calling to another regex.
### Corresponds to the `<...>` regex syntax.
###
class Q::Regex::Call does Q::Regex::Fragment {
    has Q::Identifier $.identifier;
}

### ### Q::Regex::Alternation
###
### An alternation between fragments.
###
class Q::Regex::Alternation does Q::Regex::Fragment {
    has Q::Regex::Fragment @.alternatives;
}

### ### Q::Regex::Group
###
### A regex fragment containing several other fragments.
### Corresponds to the "[" ... "]" regex syntax.
###
class Q::Regex::Group does Q::Regex::Fragment {
    has Q::Regex::Fragment @.fragments;
}

### ### Q::Regex::OneOrMore
###
### A regex fragment representing the "+" quantifier.
###
class Q::Regex::OneOrMore does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

### ### Q::Regex::ZeroOrMore
###
### A regex fragment representing the "*" quantifier.
###
class Q::Regex::ZeroOrMore does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

### ### Q::Regex::ZeroOrOne
###
### A regex fragment representing the "?" quantifier.
###
class Q::Regex::ZeroOrOne does Q::Regex::Fragment {
    has Q::Regex::Fragment $.fragment;
}

### ### Q::Term::Regex
###
### A regular expression (*regex*).
###
class Q::Term::Regex does Q::Term {
    has Q::Regex::Fragment $.contents;
}

### ### Q::Term::Array
###
### An array. Array terms consist of zero or more *elements*, each of which
### can be an arbitrary expression.
###
class Q::Term::Array does Q::Term {
    has _007::Value $.elements where &is-array;
}

subset ToV of Any where { $_ ~~ Val::Type || is-type($_) }

### ### Q::Term::Object
###
### An object.
###
class Q::Term::Object does Q::Term {
    has ToV $.type;
    has $.propertylist;
}

### ### Q::Term::Dict
###
### A dict. Dict terms consist of an entry list with zero or more key/value pairs.
###
class Q::Term::Dict does Q::Term {
    has $.propertylist;
}

### ### Q::Property
###
### An object property. Properties have a key and a value.
###
class Q::Property does Q {
    has _007::Value $.key where &is-str;
    has $.value;
}

### ### Q::PropertyList
###
### A property list in an object. Property lists have zero or more key/value
### pairs. Keys in objects are considered unordered, but a property list has
### a specified order: the order the properties occur in the program text.
###
class Q::PropertyList does Q {
    has _007::Value $.properties where &is-array = make-array([]);
}

### ### Q::Declaration
###
### A declaration; something that introduces a name.
###
role Q::Declaration {
    method is-assignable { False }
}

### ### Q::Trait
###
### A trait; a piece of metadata for a routine. A trait consists of an
### identifier and an expression.
###
class Q::Trait does Q {
    has $.identifier;
    has $.expr;

    method attribute-order { <identifier expr> }
}

### ### Q::TraitList
###
### A list of zero or more traits. Each routine has a traitlist.
###
class Q::TraitList does Q {
    has _007::Value $.traits where &is-array = make-array([]);

    method attribute-order { <traits> }
}

### ### Q::Term::Func
###
### A subroutine.
###
class Q::Term::Func does Q::Term does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }
}

### ### Q::Block
###
### A block. Blocks are used in a number of places: by routines, by
### block statements, by other compound statements (such as `if` statements)
### and by `quasi` terms and sub terms. Blocks are not, however, terms
### in their own regard.
###
### A block has a parameter list and a statement list, each of which can
### be empty.
###
class Q::Block does Q {
    has $.parameterlist;
    has $.statementlist;
    has _007::Value $.static-lexpad is rw where &is-dict = make-dict();

    method attribute-order { <parameterlist statementlist> }
}

### ### Q::Prefix
###
### A prefix operator; an operator that occurs before a term, like the
### `-` in `-5`.
###
class Q::Prefix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }
}

### ### Q::Infix
###
### An infix operator; something like the `+` in `2 + 2` that occurs between
### two terms.
###
class Q::Infix does Q::Expr {
    has $.identifier;
    has $.lhs;
    has $.rhs;

    method attribute-order { <identifier lhs rhs> }
}

### ### Q::Infix::Assignment
###
### An assignment operator. Puts a value in a storage location.
###
class Q::Infix::Assignment is Q::Infix {
}

### ### Q::Infix::Or
###
### A short-circuiting disjunction operator; evaluates its right-hand
### side only if the left-hand side is falsy.
###
class Q::Infix::Or is Q::Infix {
}

### ### Q::Infix::DefinedOr
###
### A short-circuiting "defined-or" operator. Evaluates its
### right-hand side only if the left-hand side is `none`.
###
class Q::Infix::DefinedOr is Q::Infix {
}

### ### Q::Infix::And
###
### A short-circuiting "and" operator. Evaluates its
### right-hand side only if the left-hand side is truthy.
###
class Q::Infix::And is Q::Infix {
}

### ### Q::Postfix
###
### A postfix operator; something like the `[0]` in `agents[0]` that occurs
### after a term.
###
class Q::Postfix does Q::Expr {
    has $.identifier;
    has $.operand;

    method attribute-order { <identifier operand> }
}

### ### Q::Postfix::Index
###
### An indexing operator; returns an array element or object property.
### Arrays expect integer indices and objects expect string property names.
###
class Q::Postfix::Index is Q::Postfix {
    has $.index;

    method attribute-order { <identifier operand index> }
}

### ### Q::Postfix::Call
###
### An invocation operator; calls a routine.
###
class Q::Postfix::Call is Q::Postfix {
    has $.argumentlist;

    method attribute-order { <identifier operand argumentlist> }
}

### ### Q::Postfix::Property
###
### An object property operator; fetches a property out of an object.
###
class Q::Postfix::Property is Q::Postfix {
    has $.property;

    method attribute-order { <identifier operand property> }
}

### ### Q::Unquote
###
### An unquote; allows Qtree fragments to be inserted into places in a quasi.
###
class Q::Unquote does Q {
    has $.qtype;
    has $.expr;
}

### ### Q::Unquote::Prefix
###
### An unquote which is a prefix operator.
###
class Q::Unquote::Prefix is Q::Unquote {
    has $.operand;
}

### ### Q::Unquote::Infix
###
### An unquote which is an infix operator.
###
class Q::Unquote::Infix is Q::Unquote {
    has $.lhs;
    has $.rhs;
}

### ### Q::Term::My
###
### A `my` variable declaration.
###
class Q::Term::My does Q::Term does Q::Declaration {
    has $.identifier;

    method is-assignable { True }
}

class Q::StatementList { ... }

### ### Q::Term::Quasi
###
### A quasi; a piece of 007 code which evaluates to that code's Qtree
### representation. A way to "quote" code in a program instead of running
### it directly in place. Used together with macros.
###
### The term "quasi" comes from the fact that inside the quoted code there
### can be parametric holes ("unquotes") where Qtree fragments can be
### inserted. Quasiquotation is the practice of combining literal code
### fragments with such parametric holes.
###
class Q::Term::Quasi does Q::Term {
    has $.qtype;
    has $.contents;

    method attribute-order { <qtype contents> }
}

### ### Q::Parameter
###
### A parameter. Any identifier that's declared as the input to a block
### is a parameter, including subs, macros, and `if` statements.
###
class Q::Parameter does Q does Q::Declaration {
    has $.identifier;

    method is-assignable { True }
}

### ### Q::ParameterList
###
### A list of zero or more parameters.
###
class Q::ParameterList does Q {
    has _007::Value $.parameters where &is-array = make-array([]);
}

### ### Q::ArgumentList
###
### A list of zero or more arguments.
###
class Q::ArgumentList does Q {
    has _007::Value $.arguments where &is-array = make-array([]);
}

### ### Q::Statement
###
### A statement.
###
role Q::Statement does Q {
}

### ### Q::Statement::Expr
###
### A statement consisting of an expression.
###
class Q::Statement::Expr does Q::Statement {
    has $.expr;
}

### ### Q::Statement::If
###
### An `if` statement.
###
class Q::Statement::If does Q::Statement {
    has $.expr;
    has $.block;
    has $.else = NONE;

    method attribute-order { <expr block else> }
}

### ### Q::Statement::Block
###
### A block statement.
###
class Q::Statement::Block does Q::Statement {
    has $.block;
}

### ### Q::CompUnit
###
### A block-level statement representing a whole compilation unit.
### We can read "compilation unit" here as meaning "file".
###
class Q::CompUnit is Q::Statement::Block {
}

### ### Q::Statement::For
###
### A `for` loop statement.
###
class Q::Statement::For does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }
}

### ### Q::Statement::While
###
### A `while` loop statement.
###
class Q::Statement::While does Q::Statement {
    has $.expr;
    has $.block;

    method attribute-order { <expr block> }
}

### ### Q::Statement::Return
###
### A `return` statement.
###
class Q::Statement::Return does Q::Statement {
    has $.expr = NONE;
}

### ### Q::Statement::Throw
###
### A `throw` statement.
###
class Q::Statement::Throw does Q::Statement {
    has $.expr = NONE;
}

### ### Q::Statement::Next
###
### A `next` statement.
###
class Q::Statement::Next does Q::Statement {
    method run($runtime) {
        $runtime.trigger-next();
    }
}

### ### Q::Statement::Last
###
### A `last` statement.
###
class Q::Statement::Last does Q::Statement {
    method run($runtime) {
        $runtime.trigger-last();
    }
}

### ### Q::Statement::Func
###
### A subroutine declaration statement.
###
class Q::Statement::Func does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has Q::Block $.block;

    method attribute-order { <identifier traitlist block> }
}

### ### Q::Statement::Macro
###
### A macro declaration statement.
###
class Q::Statement::Macro does Q::Statement does Q::Declaration {
    has $.identifier;
    has $.traitlist = Q::TraitList.new;
    has $.block;

    method attribute-order { <identifier traitlist block> }
}

### ### Q::Statement::BEGIN
###
### A `BEGIN` block statement.
###
class Q::Statement::BEGIN does Q::Statement {
    has $.block;
}

### ### Q::Statement::Class
###
### A class declaration statement.
###
class Q::Statement::Class does Q::Statement does Q::Declaration {
    has $.block;
}

### ### Q::StatementList
###
### A list of zero or more statements. Statement lists commonly occur
### directly inside blocks (or at the top level of the program, on the
### compunit level). However, it's also possible for a `quasi` to
### denote a statement list without any surrounding block.
###
class Q::StatementList does Q {
    has _007::Value $.statements where &is-array = make-array([]);
}

### ### Q::Expr::BlockAdapter
###
### An expression which holds a block. Surprisingly, this never
### happens in the source code text itself; because of 007's grammar, an
### expression can never consist of a block.
###
### However, it can happen as a macro call (an expression) expands into
### a block of one or more statements; that's when this Qtype is used.
###
### Semantically, the block is executed normally, and
### if execution evaluates the last statement and the statement turns out
### to have a value (because it's an expression statement), then this
### value is the value of the whole containing expression.
###
class Q::Expr::BlockAdapter does Q::Expr {
    has $.block;
}
