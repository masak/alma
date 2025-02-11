# Chapter 6: Classes

A _class_ is a form of type, common in object-oriented programming. Values
called _instances_ can be created from a (non-abstract) class; an instance `x`
created from class `X` satisfies the relation `x is X`.

Classes can also relate via subtyping. If a class `Y` is declared a subclass of
a class `X` (that is, `Y <: X`), then `y is Y` implies `y is X`. Besides the
subclassing relation, classes can also implement interfaces; see section 6.14
"Interfaces".

Parts of the class declaration's body are called _class members_, and are
either _fields_ or _methods_. A field represents property data kept within an
instance. A method represents a callable behavior of an instance. A method is
like a function, except that its body also binds the identifier `self` to the
_receiver_, the instance on which the method was called.

## 6.1 Class declarations

```
<class-declaration> ::= "class"
                        <identifier>
                        ("<" <type-parameter-list> ">")?
                        ("<:" <type-list>)?
                        <class-body>
                        <semicolon>

<class-body> ::= "{" <class-member>* "}"

<class-member> ::= <field>
                 | <method>
```

## 6.2 The `@abstract` annotation

An `@abstract` annotation on a class declaration means that the class cannot
be instantiated. The generated constructor still exists, but throws an
exception when called.

## 6.3 The `@derives` annotation

xxx

## 6.4 Fields

A _field_ represents property data belonging to an instance of the class.

```
<field> ::= "has"
            <identifier>
            "?"?
            (":" <type>)?
            ("=" <expression>)?
            <semicolon>
```

## 6.5 The `@getter` annotation

By default, fields are internal and not accessible for reading outside of the
instance in which they are held. A `@getter` annotation ensures this access,
providing a zero-parameter method (of the same name as the field) which returns
the value of the field. The return type of the method is the same as the
declared type of the field, if any.

The `@getter` annotation optionally takes a single parameter in the form of an
identifier; if provided, this identifier is used for the method name instead of
the field name.

A method may not be declared in the class body with the same name as the one
provided (by default or explicitly) by the `@getter` annotation; doing so
counts as a duplicate declaration, and is signaled as a compile-time error.

## 6.6 The `@setter` annotation

By default, fields are internal and not accessible for writing outside of the
instance in which they are held. A `@setter` annotation ensures this access,
providing a one-parameter method (of the same name as the field), which
returns the value of the parameter. The type of both the parameter and the
return value of the method is the same as the declared type of the field, if
any. The body of the method assigns the value of the parameter to the field.

The `@setter` annotation optionally takes a single parameter in the form of an
identifier; if provided, this identifier is used for the method name instead of
the field name.

A method may not be declared in the class body with the same name as the one
provided (by default or explicitly) by the `@setter` annotation; doing so
counts as a duplicate declaration, and is signaled as a compile-time error.

However, annotating a field with both `@getter` and `@setter` is explicitly
allowed, and creates a single method which is able to both return the value
bound by a field, and set the field's value from a provided argument.

## 6.7 The `@required` and `@optional` annotations

A field is _required_ by default, in that the class's constructor has a
required named parameter for the field. A `@required` annotation reaffirms
this, but is essentially a no-op.

Either of the following two are equivalent: an `@optional` annotation on a
field, or a `?` modifier on the field. These mean that the class's constructor
has an optional named parameter for the field. A field whose value is not
passed via the named parameter in its constructor is instead initialized via
the value provided via its `@default` or `@builder` annotation (which see), or
`none` if no such annotations are present. The presence of either `@default` or
a `@builder` annotation means the field is optional.

## 6.8 The `@default` annotation

A `@default` annotation expects a single argument, which is parsed as an
expression. A field not initialized via the corresponding named parameter to
the constructor, is instead initialized by evaluating this expression. The
expression is evaluated in a context where `self` is bound to the instance
being constructed.

A `@default` annotation on a field is compatible with an `@optional`
annotation, but not with a `@required` annotation. Using `@default` and
`@required` together signals a compile error.

Instead of the `@default` annotation, the `=` syntax can be used.

It is a compile error to use both the `@default` annotation and the `=` syntax
together on the same field.

## 6.9 The `@builder` annotation

A `@builder` annotation expects a single argument, an identifier which resolves
to a method available in the class. A field not initialized via the
corresponding named parameter to the constructor, is instead initialized by
calling this method. The method needs to accept zero arguments; referencing a
method which does not accept zero arguments signals a compile error.

A `@builder` annotation on a field is compatible with an `@optional`
annotation, but not with a `@required` annotation. Using `@builder` and
`@required` together signals a compile error.

A `@builder` annotation is incompatible with a `@default` annotation, and using
these two together signals a compile error.

The method call is virtual; a derived class may override the builder method,
and this overridden method will be called as part of instantiating the derived
class.

## 6.10 The `@type` annotation

A `@type` annotation expects a single argument, a type expression.

As an alternative syntax, the infix `:` can be used to specify a type.

It is a compile error to use both `@type` and `:` together.

## 6.11 The `@lazy` annotation

Supplying the `@lazy` annotation means that the property will not be
initialized on object construction, but will instead be initialized on first
property read.

Supplying a `@lazy` annotation is only allowed in combination with either a
`@default` annotation or the `=` syntax (but not both together). Supplying a
`@lazy` annotation without either of these results in a compile error.

## 6.12 The `@computed` annotation

Supplying the `@computed` annotation on a field means that any _external_
access to the property through its read accessor will also re-initialize the
property via either its `=` initialization syntax, its `@default` annotation,
or `@builder` annotation. Any direct, internal access to the property still
reads the last computed value without recomputing it.

`@computed` implies `@lazy`. Annotating a `@computed` field with `@lazy` is
allowed, but essentially a no-op.

## 6.13 The `@handles` annotation

A `@handles` annotation accepts a list of identifiers, separated by commas.
For each such identifier, this annotation declares a method of that name,
delegating to a method of the same name on the annotated property.

The `@handles` annotation can be combined with the `@default` annotation, the
`=` syntax, the `@builder` annotation, and the `@lazy` and `@computed`
annotations. A call to one of the handled methods of a `@lazy` field makes sure
to initialize the field before calling the handled method.

## 6.14 Methods

```
<method> ::= <method-header> <block> <semicolon>

<method-header> ::= "method"
                    <identifier>
                    ("<" <type-parameter-list> ">")?
                    "(" <parameter-list> ")"
                    (":" <type>)?
```

The `self` identifier is bound both in the parameter list (available in any
default expressions) and in the method body. In this scope, the `self`
identifier is bound to the instance on which the method was called.

## 6.15 The `@class` annotation

xxx

## 6.16 The `@static` annotation

xxx

## 6.17 Constructors

xxx

## 6.18 Interfaces

Interfaces declare the public part of classes; that is, methods but not fields.

```
<interface-declaration> ::= "interface"
                            <identifier>
                            ("<" <type-parameter-list> ">")?
                            ("<:" <type-list>)?
                            <interface-body>
                            <semicolon>

<interface-body> ::= "{" <interface-member>* "}"

<interface-member> ::= <method-header>
```

An interface can extend one or more other interfaces. This extension relation
must be acyclic; it is not allowed for an interface to extend itself, directly
or indirectly.

The members declared in an interface are method headers, declaring name and
parameters and return type, but no method body.

## 6.19 The `object` syntax

xxx

