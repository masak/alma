# Alma language specification

## Table of contents

### [Chapter 1](01-lexical-grammar.md#chapter-1-lexical-grammar): Lexical grammar

* [1.1 File format](01-lexical-grammar.md#11-file-format)
* [1.2 Whitespace](01-lexical-grammar.md#12-whitespace)
* [1.3 Comments](01-lexical-grammar.md#13-comments)
* [1.4 Literals](01-lexical-grammar.md#14-literals)
* [1.5 Keywords](01-lexical-grammar.md#15-keywords)
* [1.6 Identifiers](01-lexical-grammar.md#16-identifiers)
* [1.7 Operators](01-lexical-grammar.md#17-operators)
* [1.8 Delimiters](01-lexical-grammar.md#18-delimiters)
* [1.9 Punctuators](01-lexical-grammar.md#19-punctuators)
* [1.10 Scannerless parsing](01-lexical-grammar.md#110-scannerless-parsing)

### Chapter 2: Expressions

* 2.1 Literal expressions
* 2.2 Variable lookups
* 2.3 Array constructors
* 2.4 Dictionary constructors
* 2.5 Quasiquotes
* 2.6 Custom constructor
* 2.7 Function constructors
* 2.8 Call expressions
* 2.9 Indexed and keyed lookups
* 2.10 Property lookup
* 2.11 Conversion operators
* 2.12 Arithmetic operators
* 2.13 String operators
* 2.14 Range constructor
* 2.15 Type check/cast operators
* 2.16 Equality operators
* 2.17 Comparison operators
* 2.18 Logical operators
* 2.19 Assignment operators
* 2.20 Precedence table

### Chapter 3: Statements

* 3.1 Empty statement
* 3.2 Expression statement
* 3.3 `if` statement
* 3.4 `while` statement
* 3.5 `for` statement
* 3.6 `next` statement
* 3.7 `last` statement
* 3.8 `return` statement
* 3.9 `throw` statement
* 3.10 `CATCH` phaser
* 3.11 `LEAVE` phaser
* 3.12 Block statement
* 3.13 Labeled statement

### Chapter 4: Declarations

* 4.1 Variable declaration
* 4.2 Function declaration
* 4.3 Macro declaration
* 4.4 Class declaration
* 4.5 Interface declaration
* 4.6 Enum declaration
* 4.7 Import directive
* 4.8 Annotations

### Chapter 5: Functions

* 5.1 Function calls
* 5.2 Optional parameters
* 5.3 Parameter defaults
* 5.4 Rest parameter
* 5.6 Named rest parameter
* 5.7 Parameter type
* 5.8 Parameter binding
* 5.9 Function body
* 5.10 Returning from a function
* 5.11 Function return type
* 5.12 Lexical closure

### Chapter 6: Classes

* 6.1 Class declarations
* 6.2 The `@abstract` annotation
* 6.3 Fields
* 6.4 The `@getter` annotation
* 6.5 The `@setter` annotation
* 6.6 The `@required` and `@optional` annotations
* 6.7 The `@default` annotation
* 6.8 The `@builder` annotation
* 6.9 The `@type` annotation
* 6.10 The `@lazy` annotation
* 6.11 Methods
* 6.12 The `@class` annotation
* 6.13 The `@static` annotation
* 6.14 Interfaces
* 6.15 The `object` syntax

### Chapter 7: Enums

* 7.1 Enum declarations
* 7.2 Referencing enum constructors

### Chapter 8: Types

* 6.1 Array types
* 6.2 Tuple types
* 6.3 Function types
* 6.4 Union types
* 6.5 Intersection types
* 6.6 The `Any` type
* 6.7 The `Never` type
* 6.8 Type parameters
* 6.9 Type arguments
* 6.10 Type aliases

### Chapter 9: Modules

* 9.1 Modules as namespaces
* 9.2 Import
* 9.3 Export
* 9.4 Aggregate module export
* 9.5 The import binding mechanism
* 9.6 Packages and distributions

### Chapter 10: Interactivity

* 10.1 Statements in the REPL
* 10.2 Declarations in the REPL
* 10.3 Redeclarations
* 10.4 Imports
* 10.5 Debugging

### Chapter 11: The metaobject protocol

* 11.1 Classes
* 11.2 Abstract classes
* 11.3 Interfaces
* 11.4 Enums
* 11.5 Object literals
* 11.6 Modules
* 11.7 Extending the metaobject protocol

### Chapter 12: Quasiquotation

* 12.1 Basic `quote` syntax
* 12.2 Grammatical category
* 12.3 Unquotes
* 12.4 Unquotes with grammatical category
* 12.5 Lexical hygiene
* 12.6 Nested quotation

### Chapter 13: Macros

* 13.1 Macro calls
* 13.2 Macro declarations
* 13.3 Lexical hygiene

### Chapter 14: Control flow

* 14.1 The loop protocol
* 14.2 Promises
* 14.3 Effect handlers
* 14.4 Labels and `goto`
* 14.5 Continuations
* 14.6 Phasers

### Chapter 15: Stateful macros

* 15.1 Variables declared in the macro body
* 15.2 The `state` declarator
* 15.3 Macros and `state`

### Chapter 16: Regexes

* 16.1 Regex term syntax
* 16.2 Simple regex string matching
* 16.3 Match-and-replace
* 16.4 Regex substitution
* 16.5 Regex set-like operators
* 16.6 Tokenization
* 16.7 Regex interpolation

### Chapter 17: Grammars

* 17.1 Grammar declarations
* 17.2 Parsing with a grammar
* 17.3 Extending a grammar
* 17.4 The Alma standard grammar

### Chapter 18: Extending the lexer

* 18.1 Defining new literals
* 18.2 Defining new operators
* 18.3 Defining new statements
* 18.4 Defining new declarations

### Chapter 19: Parsed macros

* 19.1 The `@parsed` annotation
* 19.2 How macro parameters are affected
* 19.3 How the current grammar is extended
* 19.4 Possible conflicts during extension
* 19.5 Exporting parsed macros

### Chapter 20: Lvalues

### Chapter 21: Annotations

### Chapter 22: Operators

### Chapter 23: DSLs

### Chapter 24: Language extensions

### Chapter 25: API documentation

