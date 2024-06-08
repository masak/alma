# Chapter 6: Classes

A _class_ is a form of type, common in object-oriented programming. Values
called _instances_ can be created from a (non-abstract) class; an instance `x`
created from class `X` satisfies the relation `x is X`.

Classes can also relate via subtyping. If a class `Y` is declared a subclass of
a class `X` (that is, `Y <: X`), then `y is Y` implies `y is X`.

Parts of the class declaration's body are called _class members_, and are
either _fields_ or _methods_. A field represents data kept within an instance.
A method represents a callable behavior of an instance. A method is like a
function, except that its body also binds the identifier `self` to the instance
on which the method was called.

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

## 6.3 Fields

```
<field> ::= "has"
            <identifier>
            (":" <type>)?
            <semicolon>
```

## 6.4 The `@getter` annotation

## 6.5 The `@setter` annotation

## 6.6 The `@required` and `@optional` annotations

## 6.7 The `@default` annotation

## 6.8 The `@builder` annotation

## 6.9 The `@type` annotation

## 6.10 The `@lazy` annotation

## 6.11 Methods

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

## 6.12 The `@class` annotation

## 6.13 The `@static` annotation

