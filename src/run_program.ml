open Core
open Parsing.Lex_and_parse
open Typing.Type_checker

let maybe_pprint_ast should_pprint_ast pprintfun ast =
  if should_pprint_ast then (
    pprintfun Fmt.stdout ast ;
    Error (Error.of_string "")
    (* This ends the program (preserving existing regression tests if subsequent pipeline
       changes) *) )
  else Ok ast

let run_program ?(should_pprint_past = false) ?(should_pprint_tast = false) lexbuf =
  let open Result in
  parse_program lexbuf
  >>= maybe_pprint_ast should_pprint_past pprint_parsed_ast
  >>= type_check_program
  >>= maybe_pprint_ast should_pprint_tast pprint_typed_ast
  |> function Ok _ -> () | Error e -> eprintf "%s" (Error.to_string_hum e)