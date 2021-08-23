(**
   Centralized exception handling for the KerLang compiler
*)

exception SyntaxError of (Lexing.position * string)
exception ParseError of (Lexing.position * string)
exception CompileError of string
exception DeveloperError of string

let print_position oc (pos : Lexing.position) =
  Printf.fprintf oc "%s:%d:%d" pos.pos_fname
    pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let warning ?(name : string = "warning") (msg : string) =
  Printf.eprintf "\x1b[1;33m%s:\x1b[0m %s\n" name msg

let error ?(name : string = "error") (msg : string) =
  Printf.eprintf "\x1b[1;31m%s:\x1b[0m %s\n" name msg;
  exit 1

let located_warning ?(name : string = "warning") (pos : Lexing.position) (msg : string) =
  Printf.eprintf "\x1b[1;33m%s: (%a) \x1b[0m %s\n" name print_position (pos : Lexing.position) msg

let located_error ?(name : string = "error") (pos : Lexing.position) (msg : string) =
  Printf.eprintf "\x1b[1;31m%s: (%a) \x1b[0m %s\n" name print_position (pos : Lexing.position) msg;
  exit 1

let syntax_error = located_error ~name:"syntax error"

let parse_error = located_error ~name:"parse error"

let compile_error = error ~name:"compile error"

let dev_error msg =
  Printf.eprintf "\x1b[1;31mimplementation-bug-error:\x1b[0m %s\n" msg;
  Printf.eprintf "\x1b[1;36mnote:\x1b[0m this is a bug in the KerLang implementation, this is not your fault\n";
  exit 1
