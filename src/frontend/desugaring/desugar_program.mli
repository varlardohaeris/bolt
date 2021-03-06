(** This module is responsible for desugared the typed AST. The desugared AST simplifies
    the expressions in the typed ASTs It provides the invariant that there is no variable
    shadowing in the desugared AST *)

open Core
open Typing

val desugar_program : Typed_ast.program -> Desugared_ast.program Or_error.t

val pprint_desugared_ast : Format.formatter -> Desugared_ast.program -> unit
(** Given a formatter and desugared AST, pretty-print the AST - useful for debugging *)
