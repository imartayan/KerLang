type expr =
  | Arg of int
  | Cst of int
  | Var of string
  | Arith of binop * expr * expr
  | App of string * expr list
  | Rec of expr list
  | If of expr * expr * expr
  | Hole

and binop = ADD | MUL | SUB | DIV

type constr =
  | Takes of int
  | Let of string * expr
  | Shows of expr list
  | Uses of expr list
  | Returns of expr
  | Expects of expr * expr
  | Nothing

type declaration =
  | Function of string * string list * constr list
  | Constant of string * constr list
  | External of string * string list

type prog = declaration list

type gamma = {
  n_args    : int option;
  locals    : (string * expr) list;
  value     : expr;
}

let make_context arguments : gamma = { n_args = Some (List.length arguments); locals = []; value = Hole}

let todo () =
  Printf.eprintf "not implemented yet !\n"; assert false

let solve_one (ctx : gamma) (c : constr) =
  match c with
  | Takes n ->
    begin
      match ctx.n_args with
      | Some m -> assert (n = m); ctx
      | None -> { ctx with n_args = Some n }
    end
  | Let (x, e) ->
    begin 
      match List.assoc_opt x ctx.locals with
      | Some _ -> assert false
      | None -> { ctx with locals = (x, e)::ctx.locals }
    end
  | Shows _ -> todo ()
  | Uses _ -> todo ()
  | Returns _ -> todo ()
  | Expects (_, _) -> todo ()
  | Nothing -> ctx


let solve (_ctx : gamma) (_constraints : constr list) : Kl_IR.ast =
  todo ()

let compile (p : prog) : Kl_IR.ftable =
  List.map (function
    | External (name, _args) -> name, Kl_IR.Var 0
    | Constant (name, constraints) ->
      name, solve (make_context []) constraints
    | Function (name, args, constraints) ->
      name, solve (make_context args) constraints
  ) p