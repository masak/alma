# Chapter 4: Declarations

Declarations establish a binding between a name and a value. Unlike expressions
whose primary role is to be evaluated, and statements which are primarily
executed, declarations add their binding to the lexical environment.

A declaration belongs to its innermost enclosing block. As a block is run,
first a new frame is created, empty but linked to the frame of the innermost
surrounding block, if any. All the declarations belonging to the block get a
binding with their name, to the pseudo-value `uninitialized`. After that,
declarations initialize on two different schedules, depending on their type.

_Hoisted declarations_ initialize immediately, meaning that their binding will
be initialized by the time the first statement is executed. Hoisted
declarations of the same block are free to mutually refer to each other, since
by design their initialization doesn't evaluate any expressions or execute any
statements; when they do refer to each other, they do so in code which is not
yet running. The specific initialization order of hoisted declarations in a
block is unobservable; any order produces the same end result.

_Inline declarations_ have an expression called an _initialized expression_,
which is evaluated when execution reaches the declaration. The resulting value
is then used to initialize the declared name. Reading a variable before it has
been initialized (includes in the evaluation of the initializer expression
itself) results in a runtime error.

Many declaration forms are _complex_ and contain nested declarations. These
nested declarations are typically equipped with their own scope. For example,
function declarations contain parameters, which declare names to be used in the
function body. Classes declare fields or methods, which declare names to be
used in connection with instances of the class.

A declaration needs to have a name which is unique in its scope; any two
declarations in the same scope must have distinct names.

```
<declaration> ::= <variable-declaration>
               |  <function-declaration>
               |  <macro-declaration>
               |  <class-declaration>
               |  <interface-declaration>
               |  <enum-declaration>
```

## 4.1 Variable declaration

A _variable declaration_ adds a new name to a scope, initially letting the
binding be uninitialized. Once execution reaches the point of the declaration,
its initializer is evaluated (if there is one) and the resulting value is
assigned to the variable.

```
<variable-declaration> ::= "my"
                           <identifier>
                           (":" <type>)?
                           ("=" <expression>)?
                           <semicolon>
```

## 4.2 Function declaration

A _function declaration_ adds a new name to a scope, and binds it to a
function.

```
<function-declaration> ::= "func"
                           <identifier>
                           ("[" <type-parameter-list> "]")?
                           "(" <parameter-list> ")"
                           (":" <type>)?
                           <block>
                           <semicolon>

<parameter-list> ::= <paramter>* %% ","

<parameter> ::= "..."?
                <identifier>
                "?"?
                (":" <type>)?
                ("=" <expression>)?
```

For more about functions, including how they are invoked, see [Chapter 5:
Functions](05-functions.md).

## 4.3 Macro declaration

A _macro declaration_ adds a new name to a scope, and binds it to a macro.

```
<macro-declaration> ::= "macro"
                        <identifier>
                        ("[" <type-parameter-list> "]")?
                        "(" <parameter-list> ")"
                        (":" <type>)?
                        <block>
                        <semicolon>
```

For more about macros, including how they are invoked, see [Chapter 13:
Macros](13-macros.md).

## 4.4 Class declaration

A _class declaration_ adds a new name to a scope, and binds it to a class.

For more about classes, see [Chapter 6: Classes](06-classes.md).

## 4.5 Interface declaration

An _interface declaration_ adds a new name to a scope, and binds it to an
interface.

For more about interfaces, see [Chapter 6: Classes](06-classes.md).

## 4.6 Enum declaration

An _enum declaration_ adds a new name to a scope, and binds it to an enum.

For more about enum declarations, see [Chapter 7: Enums](07-enums.md).

## 4.7 Import directive

An _import directive_ is not a kind of declaration, but does have the effect of
adding names to the current scope.

```
<import-directive> ::= "import"
                       "{" <import-list> "}"
                       "from"
                       <string>
                       <semicolon>

<import-list> ::= <import-item>* %% ","

<import-item> ::= <identifier>
                  ("as" <identifier>)?
```

Although an import directive doesn't count as a declaration, the import items
listed count as nested declarations.

## 4.8 Annotations

Annotations add metadata to declarations, such as providing a field declaration
with a setter, or providing a parameter with a default.

All declaration forms, including variable declarations, function declarations,
macro declarations, class declarations, interface declarations, and enum
declarations, can be preceded by annotations.

```
<annotated-declaration> ::= <annotation>* <declaration>

<annotation> ::= "@" <identifier>
                 ("(" <argument-list>* ")")?
```

Annotations can also be attached to nested declarations, including parameters,
field declarations, method declarations, enum constants, and import items.

