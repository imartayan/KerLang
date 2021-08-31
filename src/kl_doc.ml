
let head = "<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Document</title>
</head>\n"


let dump_spec oc toks =
  let l = Kl_constraints.split_lines toks in
  List.iter (fun x ->
      String.concat " " (List.map Kl_constraints.untouched_string_of_tok x)
      |> Printf.fprintf oc "    <i>%s</i><br>\n"
    ) l

let docgen oc p =
  Printf.fprintf oc "%s" head;
  Printf.fprintf oc "<body>\n";
  List.iter (fun (Kl_parsing.Spec (_, name, spec)) ->
    Printf.fprintf oc "  <p>\n";
    dump_spec oc spec;
    Printf.fprintf oc "  </p>\n";
    Printf.fprintf oc "  <pre><code>function %s;</code></pre>\n" name;
  ) p