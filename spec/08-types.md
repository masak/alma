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

## 6.1 Array types

## 6.2 Tuple types

## 6.3 Union types

## 6.4 Intersection types

## 6.5 The `Any` type

## 6.6 The `Never` type

