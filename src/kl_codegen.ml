(** {1 Codegen}

    Code generation module for KerLang
*)

open Kl_IR

module type TermRealizer = sig
  (** Realize an anonymous term *)
  val realize_term : Format.formatter -> ast -> unit

  (** Realize a named declaration *)
  val realize_decl : Format.formatter -> string -> ast -> unit

  (** Realize a header containing a comment and maybe some helper functions *)
  val realize_header : Format.formatter -> unit

  (** Realize an automatic call to the "main" function (provided it exists) *)
  val realize_entrypoint_call : Format.formatter -> unit
end

(** Type of kl_IR realizers *)
module Realizer (X : TermRealizer) = struct
  include X
  let realize oc (prog_list : (string * ast) list) =
    let has_main =
      List.exists (fun (name, prog) ->
          let is_main = (name = "main") in
          if is_main then begin
            let main_params_count = ast_count_params prog in
            if main_params_count <> 0 then begin
              assert false
            end
          end;
          is_main
        ) prog_list in
    realize_header oc;
    List.iter (fun (name, prog) -> realize_decl oc name prog) prog_list;
    if has_main then realize_entrypoint_call oc
end

module ML_Realizer = Realizer (struct
  let realize_header oc =
    Kl_2ml.emit_header oc

  let realize_term oc prog =
    Kl_2ml.emit_ast_as_function oc prog

  let realize_decl oc name prog =
    Kl_2ml.emit_ast_as_function_decl oc name prog

  let realize_entrypoint_call oc =
    Kl_2ml.emit_entrypoint_call oc
end)

module PY_Realizer = Realizer (struct
  let realize_header oc =
    Kl_2py.emit_header oc

  let realize_term oc prog =
    Kl_2py.emit_ast oc prog

  let realize_decl oc name prog =
    Kl_2py.emit_ast_as_function_decl oc name prog

  let realize_entrypoint_call oc =
    Kl_2py.emit_entrypoint_call oc
end)


module C_Realizer = Realizer (struct 
  let realize_header oc =
    Kl_2c.emit_header oc

  let realize_term oc prog =
    Kl_2c.emit_ast oc prog

  let realize_decl oc name prog =
    Kl_2c.emit_ast_as_function_decl oc name prog

  let realize_entrypoint_call oc =
    Kl_2c.emit_entrypoint_call oc
end)

type lang = ML | PY | C

let pp_lang oc = function
  | ML -> Printf.fprintf oc "OCaml"
  | PY -> Printf.fprintf oc "Python"
  | C -> Printf.fprintf oc "C"

let realize oc lang prog =
  Printf.printf "[Realizing the program in \x1b[1;36m%a\x1b[0m]\n" pp_lang lang;
  let fmt = Format.formatter_of_out_channel oc in
  match lang with
  | ML ->
    ML_Realizer.realize fmt prog
  | PY ->
    PY_Realizer.realize fmt prog
  | C ->
    C_Realizer.realize fmt prog

let executes prog =
  Kl_IR.flookup "main" prog
  |> Kl_IR.eval [] prog