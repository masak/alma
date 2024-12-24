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
                        ("[" <type-parameter-list> "]")?
                        ("<:" <type>)?
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

A _field_ represents property data of an instance of a class.

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

A field is _required_ by default, which means that the class's constructor has
a required named parameter for the field. A `@required` annotation reaffirms
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

## 6.10 The `@type` annotation

A `@type` annotation expects a single argument, an expression which needs to
statically evaluate to a `Type`.

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

xxx

## 6.13 Methods

```
<method> ::= "method"
             <identifier>
             ("[" <type-parameter-list> "]")?
             "(" <parameter-list> ")"
             (":" <type>)?
             <block>
             <semicolon>
```

The `self` identifier is bound both in the parameter list (available in any
default expressions) and in the method body. In this scope, the `self`
identifier is bound to the instance on which the method was called.

## 6.14 The `@class` annotation

## 6.15 The `@static` annotation

## 6.16 Interfaces

## 6.17 The `object` syntax

