type report = (int * string)

exception AbortPass of report

type reporters = {
  ko : int -> string -> unit;
  ok : string -> unit;
  info : string -> unit;
}

let _std_ko_reporter i msg =
  Printf.eprintf "Error (at line %d) : %s\n" i msg;
  raise (AbortPass (i, msg))

let _std_ok_reporter msg =
  Printf.eprintf "Ok : %s\n" msg

let _std_info_reporter msg =
  Printf.eprintf "Info : %s\n" msg

let _std_reporter = {
  ok = _std_ok_reporter; 
  ko = _std_ko_reporter;
  info = _std_info_reporter
}

let _js_ko_reporter i msg =
  let open Js_of_ocaml in
  let open Dom_html in
  let report = getElementById_exn "error-report" in
  let content = Printf.sprintf "<div class=\"ko\">Error (at line %d): %s</div>" i msg in
  report##.innerHTML := Js.string content

let _js_ok_reporter msg =
  let open Js_of_ocaml in
  let open Dom_html in
  let report = getElementById_exn "error-report" in
  let content = Printf.sprintf "<div class=\"ok\">Ok: %s</div>" msg in
  report##.innerHTML := Js.string content

let _js_info_reporter msg =
  let open Js_of_ocaml in
  let open Dom_html in
  let report = getElementById_exn "error-report" in
  let content = Printf.sprintf "<div class=\"info\">Info: %s</div>" msg in
  report##.innerHTML := Js.string content

let _js_reporter = {
  ko = _js_ko_reporter;
  ok = _js_ok_reporter;
  info = _js_info_reporter;
}

let _reporter = ref _std_reporter

let set_reporter rep = _reporter := rep

let ko_report line err = !_reporter.ko line err

let ok_report msg = !_reporter.ok msg

let info_report msg = !_reporter.info msg

let set_reporter = function
  | `JS -> set_reporter _js_reporter
  | `STD -> set_reporter _std_reporter