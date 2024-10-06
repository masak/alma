# Chapter 8: Types

In Alma, any value at runtime belongs to a _type_. Some values belong to more
than one type, but all values belong to at least one type.

We say that a value `v` _belongs_ to a type `T` if the expression `v is T`
gives a truthy result.

A class is a form of type. Values are called _instances_ if they belong to a
class.

An interface is a form of type. If `v` is an instance of class `C`, which
implements interface `I`, then `v is I` gives a truthy result.

An enum is a form of type. An enumeration constant `E.e` belongs to exactly one
enum `E`, namely the one it was declared in.

The built-in types `Int`, `Str`, `Bool`, `Array`, `Dict`, `Set`, `Bag`, and
`Map` are also types.

Types exist both at compile time and at runtime. The declaration forms for
classes, interfaces, and enums make sure to make the newly declared type
available at compile time. Declaring a variable or parameter or return value to
be of a given type is also a compile-time notion. The expression occurring on
the left of a colon (`:`) in a declaration must be constructible at compile
time so that the compilation can see it and make use of it.

On the other hand, all the core features of Alma are guaranteed to work without
such type annotations. Alma is a dynamically typed language, in the sense that
the program needs to be well-formed syntactically and with respect to scoping
in order to run, but does _not_ need to pass any checks made by the type
inference algorithm. The adage "well-typed programs do not go wrong" reminds us
that when a (sound) type-checker has given our program its blessing, certain
classes of runtime error are ruled out. Alma has good support for static typing
in the sense that Alma's type-checker provides the same guarantee -- but you're
not prevented from running the program absent this guarantee, it's just that
you do so with the understanding that those runtime errors are not ruled out.

## 6.1 Array types

## 6.2 Tuple types

## 6.3 Function types

## 6.4 Union types

## 6.5 Intersection types

## 6.6 The `Any` type

## 6.7 The `Never` type

