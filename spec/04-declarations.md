# Chapter 4: Declarations

Declarations establish a binding between a name and a value. Unlike expressions
whose primary role is to be evaluated, and statements which are primarily
executed, declarations add their binding to the lexical environment.

A declaration belongs to its innermost enclosing block. As a block is run,
first a new frame is created, empty but linked to the frame of the innermost
surrounding block, if any. All the declarations belonging to the block get a
binding with their name, to a pseudo-value called `uninitialized`. After that,
declarations initialize on two different schedules, depending on their type.

_Hoisted declarations_ initialize immediately, meaning that their binding will
be initialized by the time the first statement is executed. Hoisted
declarations of the same block are free to mutually refer to each other, since
by design their initialization doesn't evaluate any expressions or execute any
statements; when they do refer to each other, they do so in code which is not
yet running. The specific initialization order of hoisted declarations in a
block is unobservable; any order produces the same end result.

_Inline declarations_ (only variable declarations in the base language)
have an expression called an _initialized expression_, which is evaluated the
moment execution reaches the declaration. The resulting value is then used to
initialize the declared name. Reading a variable before it has been initialized
(which includes in the initializer expression itself) results in a runtime
error.

Many declaration forms are _complex_ and contain nested declarations. These
nested declarations are typically for a different scope. For example, function
declarations contain parameters, which declare names to be used in the function
body. Classes declare fields or methods, which declare names to be used in
connection with instances of the class.

```
<declaration> ::= <variable-declaration>
               |  <function-declaration>
               |  <macro-declaration>
               |  <class-declaration>
               |  <interface-declaration>
               |  <enum-declaration>
```

## 4.1 Variable declaration

## 4.2 Function declaration

```
<function-declaration> ::= "func"
                           <identifier>
                           "(" <parameter-list> ")"
                           (":" <type>)?
                           <block>
                           <semicolon>
```

## 4.3 Macro declaration

## 4.4 Class declaration

## 4.5 Interface declaration

## 4.6 Enum declaration

## 4.7 Import directive

## 4.8 Annotations

