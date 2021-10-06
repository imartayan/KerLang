(**
   {1 The glorious KerLang Compiler}

   also known as the glorious Ker-Lann Compiler but who cares ?
*)

(** Parse a KerLang file and print the result of the parsing *)
(* let parse_file f =
  let lexbuf = Lexing.from_channel (open_in f) in
  let blocks = ref [] in
  Lexing.set_filename lexbuf f;
  try while true do
      blocks := Kerlang.Kl_parser.block lexbuf::!blocks
    done; []
  with
  | Kerlang.Kl_parser.Eof -> List.rev !blocks
  | Kerlang.Kl_errors.SyntaxError (pos, msg) ->
    Kerlang.Kl_errors.syntax_error pos msg

let usage_msg = Sys.argv.(0) ^ " [-verbose] [-x] <srcfile> -o <output> -html <docfile>"

let verbose = ref false
let input_files = ref ""
let output_file = ref ""
let doc_file = ref ""
let output_lang : Kerlang.Kl_codegen.lang option ref = ref None
let exec = ref false
let error msg = raise (Arg.Bad msg)

let check () =
  if !output_file = "" then
    Kerlang.Kl_errors.warning "no output file provided"

let anon_fun filename =
  input_files := filename

let set_out_lang s =
  begin match Filename.extension s with
    | ".ml" -> output_lang := Some ML
    | ".py" -> output_lang := Some PY
    | ".c" -> output_lang := Some C
    | _ as ext ->
      error ("Unknown file extension '" ^ ext ^ "' (known extensions are .ml .py .c")
  end;
  output_file := s

let speclist =
  [("-verbose", Arg.Set verbose, "Output debug information");
   ("-o", Arg.String set_out_lang, "Set output file name, extension must be .ml, .py or .c");
   ("-html", Arg.Set_string doc_file, "generate the doc");
   ("-x", Arg.Set exec, "Execute the main function")]


let[@inline] generate_ir p =
  Kerlang.Kl_codegen.emit_kl_ir p

let[@inline] realize_ir p =
  if !output_file <> "" then
    Kerlang.Kl_codegen.realize
      (open_out !output_file)
      (Option.get !output_lang) p

let[@inline] exec_ir p =
  if !exec then begin
    Printf.printf "\n[Executing \x1b[1;36mmain\x1b[0m]\n";
    Kerlang.Kl_codegen.executes p
    |> Printf.printf "[Result : \x1b[1;32m%d\x1b[0m]\n"
  end

let (|>!) x f = f x; x

let generate_doc p =
  if !doc_file <> "" then
    let oc = open_out !doc_file in
    Kerlang.Kl_doc.docgen (Format.formatter_of_out_channel oc) p;
    close_out oc


let () =
  Arg.parse speclist anon_fun usage_msg;
  begin try check () with Arg.Bad msg ->
      Printf.eprintf "\x1b[1;31merror:\x1b[0m %s\n\n" msg;
      Arg.usage speclist usage_msg;
      exit 1
  end;
  try
    let spec = parse_file !input_files in
    let code = generate_ir spec in
    generate_doc spec;
    realize_ir code;
    exec_ir code
  with
  | Kerlang.Kl_errors.AbortPass _ -> ()
  | _ -> ()
  (* | Kerlang.Kl_errors.DeveloperError msg ->
    Kerlang.Kl_errors.dev_error msg
  | Kerlang.Kl_errors.SyntaxError (pos, msg) ->
    Kerlang.Kl_errors.syntax_error pos msg
  | Kerlang.Kl_errors.ParseError (pos, msg) ->
    Kerlang.Kl_errors.parse_error pos msg
  | Kerlang.Kl_errors.CompileError msg ->
    Kerlang.Kl_errors.compile_error msg *) *)
