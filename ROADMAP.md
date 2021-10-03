# New structure of the compiler

This document describe the expected structure of the new KerLang compiler.

## Compilation pipeline

The new KerLang compiler will process `.kl` in several steps :

1. **Parsing**: At this stage, we parse the input files. Specifications are analyzed using [*schema*](https://github.com/jdprod/Schema.git) and converted to constraints.
   + **input**: KerLang source files
   + **output**: KerLang constraints
   + **exceptions**: `ParsingError of string`
2. **Solving**: Constraints are solved to generate intermediate code. Errors may be reported if the constraints are'nt satisfiable.
   + **input**: KerLang constraints
   + **output**: KL_IR
   + **exceptions**: `ResolutionError of string`
3. **Code generation**: KL_IR programs are compiled down to target languages (OCaml, Python or C).
   + **input**: KL_IR
   + **output**: OCaml | Python | C
   + **exceptions**: `GenerationError of lang * string`

## Modules

Modules of the new compiler will be the following :

+ `kl_parser`: KerLang main parser
+ `kl_solver`: KerLang constraint solver
+ `kl_codegen`: KerLang code generator
  + `kl_2ml` (the OCaml generator)
  + `kl_2py` (the Python generator)
  + `kl_2c` (the C generator)

## Submodules

The [Schema](https://github.com/jdrprod/Schema) package will be added as a submodule and used as the backbone of the parser.

## OCaml intermediate representations

The compiler works mainly with 3 intermediate representations


1. **Kl_programs**: KerLang source language
2. **Kl_constraints**: the formalized language of KerLang specifications
3. **Kl_IR**: The tinny functional language targeted by the KerLang solver

### Kl_programs

Abstract syntax of KerLang programs

```ocaml
type kl_declaration =
  | Function of string * string list * kl_constraint list
  | Constant of string * kl_constraint list
  | External of string * string list

type kl_prog = declaration list
```

KerLang programs are list of declarations. There are 3 kinds of declarations :
1. **Functions** are named functions taking inputs and producing outputs. They are described by a list of `kl_constraints`. Arguments can optionally be named and listed (to omit named arguments just pass `[]` as the arguments list)
2. **Constant** are named constant values described by a list of `kl_constraints`. They behave exactly as **Function**s but errors are reported if they use free variables in their descriptions.
3. **External** are named opaque functions. They are not excepted to be implemented in KerLang. The compiler process them as if there were already defined in the language targeted during compilation.

### Kl_constraints

Abstract syntax of formalized KerLang constraints

```ocaml
type kl_constraint =
  | Takes of int
  | Let of string * expr
  | Shows of expr list
  | Uses of expr list
  | Returns of expr
  | Expects of expr * expr
  | Nothing

and expr =
  | Arg of int
  | Cst of int
  | Var of string
  | Arith of binop * expr * expr
  | App of string * expr list
  | Rec of expr list
  | If of expr * expr * expr
  | Hole

and binop = ADD | MUL | SUB | DIV
```

### Kl_IR

Abstract syntax of the KerLang Intermediate Language

```ocaml
type kl_ir =
  | App of op * kl_ir list
  | Cst of int
  | Var of int
  | If of kl_ir * kl_ir * kl_ir

and type op =
  OUT | ADD | MUL | DIV | SUB | SELF | FUN of string
```