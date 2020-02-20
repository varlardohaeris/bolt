open Core
open Desugaring.Desugared_ast
open Data_race_checker_env
open Update_identifier_regions
open Ast.Ast_types

let type_linear_obj_method_args class_defns obj_name obj_class args_ids loc =
  if class_has_capability obj_class Linear class_defns then
    if List.exists ~f:(identifier_matches_var_name obj_name) args_ids then
      Error
        (Error.of_string
           (Fmt.str "%s One of linear object %s's method's arguments aliases it@."
              (string_of_loc loc) (Var_name.to_string obj_name)))
    else Ok () (* no aliasing in arguments *)
  else (* not linear so we don't care *) Ok ()

let type_linear_args class_defns args_ids loc =
  let linear_args_ids =
    List.filter
      ~f:(fun arg_id -> identifier_has_capability arg_id Linear class_defns)
      args_ids in
  let matching_ids = function
    | Variable (_, var_name, _) ->
        List.filter ~f:(identifier_matches_var_name var_name) args_ids
    | ObjField _ as id          -> List.filter ~f:(fun arg_id -> id = arg_id) args_ids
  in
  (* for all linear identifiers, make sure no other identifier matches that linear
     identifier *)
  if
    List.for_all
      ~f:(fun linear_arg_id -> List.length (matching_ids linear_arg_id) = 1)
      linear_args_ids
  then Ok ()
  else
    Error
      (Error.of_string
         (Fmt.str "%s Linear arguments are duplicated@." (string_of_loc loc)))

let filter_regions_with_linear_state class_name class_defns _ curr_region =
  not (region_fields_have_capability curr_region class_name Linear class_defns)

let type_linear_object_references obj_name obj_class class_defns block_expr =
  let obj_aliases = find_aliases_in_block_expr obj_name block_expr in
  (* update aliases so they do not have access to linear state. *)
  List.fold ~init:block_expr
    ~f:(fun acc_block_expr obj_alias ->
      update_identifier_regions_block_expr obj_alias
        (filter_regions_with_linear_state obj_class class_defns)
        acc_block_expr)
    obj_aliases

let rec type_linear_regions_block_expr class_defns (Block (loc, type_expr, exprs)) =
  match exprs with
  | []                  -> Block (loc, type_expr, exprs)
  | expr :: other_exprs ->
      (* if this expression is a declaration of a linear object, we type it in subsequent
         exprs + possibly update the block as a result. *)
      let possibly_updated_other_exprs_block =
        let other_exprs_block = Block (loc, type_expr, other_exprs) in
        match expr with
        | Let (_, var_type, var_name, _) -> (
          match var_type with
          | TEClass (var_class, _) ->
              if class_has_capability var_class Linear class_defns then
                type_linear_object_references var_name var_class class_defns
                  other_exprs_block
              else other_exprs_block
          | _                      -> other_exprs_block )
        | _ -> other_exprs_block in
      (* recurse on the subsequent expressions in the block *)
      type_linear_regions_block_expr class_defns possibly_updated_other_exprs_block
      |> fun (Block (_, _, updated_other_exprs)) ->
      Block (loc, type_expr, expr :: updated_other_exprs)