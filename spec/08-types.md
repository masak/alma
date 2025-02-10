# Chapter 8: Types

In Alma, any value at runtime belongs to a _type_. Some values belong to more
than one type, but all values belong to at least one type. We say that a value
`v` _belongs_ to a type `T` if the expression `v is T` gives a truthy result.

A class is a form of type. Values are called _instances_ if they belong to a
class.

Interfaces are types. If `v` is an instance of class `C`, which implements
interface `I`, then `v is I` gives a truthy result.

Enums are types. An enumeration constant `E.e` belongs to exactly one enum `E`,
namely the one it was declared in.

The built-in types `Int`, `Str`, `Bool`, `Array`, `Dict`, `Set`, `Bag`, and
`Map` are also types.

Types exist both at compile time and at runtime. The declaration forms for
classes, interfaces, and enums make sure to make the newly declared type
available at compile time. Declaring a variable or parameter or return value to
be of a given type is also a compile-time notion. The expression occurring on
the left of a colon (`:`) in a declaration must be available at compile time so
that the compilation can see it and make use of it.

On the other hand, all the core features of Alma are guaranteed to work without
such type annotations. Alma is a dynamically typed language, in the sense that
the program needs to be well-formed syntactically and with respect to scoping
in order to run, but does _not_ need to pass any checks made as part of type
inference.

## 6.1 Array types

An _array type_ `Array<T>` is a type of arrays whose elements are of type `T`.
An array constructor `[e1, e2, ..., e3]` is normally created with the type
`Array<Any>`, with no restriction on the type of its elements. There are three
ways to provide an array with a narrower element type.

The first way is to use the `as` expression to narrow the type of the array:

```
let ints = [1, 2, 3, 4] as Array<Int>;
say type(ints);         // Array<Int>
```

This way is only allowed on array constructors as above; the constructed array
will be constructed with the given element type.

Trying to build an array with an element not belonging to the indicated element
type results in (at the latest) a runtime error:

```
let notAllInts = [1, 2, "three", 4] as Array<Int>;      // error: type mismatch
```

Note that using `as` in this way only works for array construction. Using `as`
on a variable containing an existing array only has the effect of asserting
that the variable already has exactly the indicated runtime type:

```
let ints = [1, 2, 3, 4] as Array<Int>;
let values = [1, 2, 3, 4];

ints as Array<Int>;         // succeeds
ints as Array<Str>;         // fails
ints as Array<Any>;         // fails

values as Array<Int>;       // fails
values as Array<Str>;       // fails
values as Array<Any>;       // succeeds
```

The second way is to use the custom constructor syntax with a generic
parameter:

```
let ints = Array<Int>::[1, 2, 3, 4];        // Array<Int>
let values = Array::[1, 2, 3, 4];           // Array<Any>
```

This also works on all other built-in collection data types.

The third way is to declare the type in a variable declaration in which the
array is constructed:

```
let ints: Array<Int> = [1, 2, 3, 4];
```

Note that, same as the `as` operator, this special behavior (of imbuing the
runtime type of the array with the element type) only works when the type
annotation is in direct contact with the array constructor.

## 6.2 Tuple types

## 6.3 Function types

## 6.4 Union types

## 6.5 Intersection types

## 6.6 The `Any` type

## 6.7 The `Never` type

## 6.8 Type parameters

## 6.9 Type arguments

## 6.10 Type aliases

## 6.11 Type conversions

## 6.12 Type inference

