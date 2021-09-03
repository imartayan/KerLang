open Kerlang
open Js_of_ocaml

let parse_string s =
  let lexbuf = Lexing.from_string s in
  let blocks = ref [] in
  try while true do
      blocks := Kl_parser.block lexbuf::!blocks
    done; []
  with
  | Kl_parser.Eof -> List.rev !blocks
  | Kl_errors.SyntaxError (pos, msg) ->
    Kl_errors.syntax_error pos msg

let js_of_tok = function
  | Kl_parsing.Int (_, i) ->
    object%js
      val tokType = Js.string "int"
      val tokData = Js.string (string_of_int i)
    end
  | Kl_parsing.Word (_, w) ->
    object%js
      val tokType = Js.string "word"
      val tokData = Js.string w
    end
  | Kl_parsing.Sep ->
    object%js
      val tokType = Js.string "sep"
      val tokData = Js.string ""
    end

let list_to_array l =
  Array.init (List.length l) (List.nth l)
  |> Js.array

let js_of_spec (Kl_parsing.Spec (_, name, toks)) =
  object%js
    val functionName = Js.string name
    val functionSpec = List.map js_of_tok toks |> list_to_array
  end

let _ =
  Js.export "Kerlang" (object%js
    method compile s =
      parse_string (Js.to_string s)
      |> Format.asprintf "%a" Kl_doc.dump_specs

    method generatePY s =
      let specs = parse_string (Js.to_string s) in
      object%js
        val specs =
          Format.asprintf "%a" Kl_doc.dump_specs specs
        val result =
          Kl_codegen.emit_kl_ir specs
          |> Format.asprintf "%a" Kl_codegen.PY_Realizer.realize
      end

    method generateML s =
      let specs = parse_string (Js.to_string s) in
      object%js
        val specs =
          Format.asprintf "%a" Kl_doc.dump_specs specs
        val result =
          Kl_codegen.emit_kl_ir specs
          |> Format.asprintf "%a" Kl_codegen.ML_Realizer.realize
      end
    
    method generateC s =
      let specs = parse_string (Js.to_string s) in
      object%js
        val specs =
          Format.asprintf "%a" Kl_doc.dump_specs specs
        val result =
          Kl_codegen.emit_kl_ir specs
          |> Format.asprintf "%a" Kl_codegen.C_Realizer.realize
      end
  end)
