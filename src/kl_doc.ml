
let head = "<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Document</title>
</head>

<style>
    html {
      margin: 0;
      display: flex;
      flex-direction: column;
      width: 100%;
      align-items: center;
    }

    body {
      display: flex;
      flex-direction: column;
    }

    p {
      transition: height linear;
      transition-duration: 0.3s;
      overflow: hidden;
    }

    span:hover {
      text-decoration: underline;
      cursor: pointer;
    }
</style>\n"

let script = "<script>
  let codes = document.getElementsByTagName('code')
  for (element of codes) {
    let spec_id = 'spec' + parseInt(element.id.substring(4))
    let spec = document.getElementById(spec_id)
    let height = spec.offsetHeight
    spec.style.height = height
    spec.is_shown = true
    element.addEventListener('click', () => {
      if (spec.is_shown) {
        spec.is_shown = false
        spec.style.height = 0
      } else {
        spec.is_shown = true
        spec.style.height = height
      }
    })
  }
</script>\n"


let dump_spec oc toks =
  let l = Kl_constraints.split_lines toks in
  List.iter (fun x ->
      String.concat " " (List.map Kl_constraints.untouched_string_of_tok x)
      |> Printf.fprintf oc "    <i>%s</i><br>\n"
    ) l

let docgen oc p =
  Printf.fprintf oc "%s" head;
  Printf.fprintf oc "<body>\n";
  List.iteri (fun i (Kl_parsing.Spec (_, name, spec)) ->
    Printf.fprintf oc "  <p class=\"spec\" id=\"spec%d\">\n" i;
    dump_spec oc spec;
    Printf.fprintf oc "  </p>\n";
    Printf.fprintf oc "  <code id=\"code%d\"><span style=\"color: red\">function</span> %s;</code>\n" i name;
  ) p;
  Printf.fprintf oc "%s" script;
  Printf.fprintf oc "</body>\n";
  Printf.fprintf oc "</html>\n"
