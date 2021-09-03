(** C code generator - To transpile to C. *)

open Kl_IR

let emit_header oc =
  Format.fprintf oc "
/*----------------------------------------------------*/
/* This code is generated by the KerLang compiler and */
/* is not intended to be manually edited              */
/*----------------------------------------------------*/

#include <stdlib.h> /* exit, EXIT_FAILURE */
#include <stdio.h> /* printf, fprintf */

static inline int out(int x0, int x1)
{
    printf(\"%%d\\n\", x0);
    return x1;
}
static inline int kl_add(int x0, int x1)
{
    return x0 + x1;
}
static inline int kl_sub(int x0, int x1)
{
    return x0 - x1;
}
static inline int kl_mul(int x0, int x1)
{
    return x0 * x1;
}
static inline int kl_div(int x0, int x1)
{
    if (x1 == 0)
    {
        fprintf(stderr, \"Division by zero fatal error: aborting.\\n\");
        exit(EXIT_FAILURE);
    }
    return x0 / x1;
}
\n"

let emit_indent oc (indent_lvl : int) =
  for _ = 0 to indent_lvl - 1 do
    Format.fprintf oc "    "
  done

let emit_param_sequence oc (params_count : int) = 
  for i = 0 to params_count - 2 do
    Format.fprintf oc "int x%d, " i
  done;
  if params_count >= 1 then begin
    Format.fprintf oc "int x%d" (params_count - 1)
  end else begin
    Format.fprintf oc "void"
  end

let rec emit_ast oc ?(self_name : string option = None) ?(indent_lvl : int = 0) (func : ast) =
  match func with
  | Cst value ->
    Format.fprintf oc "\n%a%d" emit_indent indent_lvl value
  | Var id ->
    Format.fprintf oc "\n%ax%d" emit_indent indent_lvl id
  | App (op, args) ->
    Format.fprintf oc "\n%a%a(%a)"
      emit_indent indent_lvl
      (emit_op ~self_name) op
      (emit_ast_list ~self_name ~indent_lvl:(indent_lvl + 1)) args
  | If (cond, ifcase, elsecase) ->
    Format.fprintf oc "%a ?%a :%a"
      (emit_ast ~self_name ~indent_lvl:(indent_lvl)) cond
      (emit_ast ~self_name ~indent_lvl:(indent_lvl)) ifcase
      (emit_ast ~self_name ~indent_lvl:(indent_lvl)) elsecase

and emit_ast_list oc ?(self_name : string option = None) ?(indent_lvl : int = 0) (ast_list : ast list) =
  match ast_list with
  | [] -> ()
  | ast::[] ->
    emit_ast oc ~self_name:(self_name) ~indent_lvl:(indent_lvl) ast
  | ast::q ->
    emit_ast oc ~self_name:(self_name) ~indent_lvl:(indent_lvl) ast;
    Format.fprintf oc ", ";
    emit_ast_list oc ~self_name:(self_name) ~indent_lvl:(indent_lvl) q

and emit_op oc ?(self_name : string option = None) (op: op) =
  match op with
  | OUT ->
    Format.fprintf oc "out";
  | ADD ->
    Format.fprintf oc "kl_add"
  | SUB ->
    Format.fprintf oc "kl_sub"
  | MUL ->
    Format.fprintf oc "kl_mul"
  | DIV ->
    Format.fprintf oc "kl_div"
  | FUN name ->
    Format.fprintf oc "%s" name
  | SELF ->
    match self_name with
    | None -> Kl_errors.dev_error "self_name needed but not provided"
    | Some name -> Format.fprintf oc "%s" name

let emit_ast_as_function_decl oc ?(indent_lvl : int = 0) (name : string) (func : ast) =
  emit_indent oc indent_lvl;
  Format.fprintf oc "int %s(%a)\n{\n%areturn%a;\n}\n\n"
    name
    emit_param_sequence (ast_count_params func)
    emit_indent (indent_lvl + 1)
    (emit_ast ~indent_lvl:(indent_lvl + 2) ~self_name:(Some name)) func

let emit_entrypoint_call oc = 
  Format.fprintf oc "%s" "\n"