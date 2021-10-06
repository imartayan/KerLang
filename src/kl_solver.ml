type expr =
  | Arg of int
  | Cst of int
  | Var of string
  | Arith of binop * expr * expr
  | Show of expr * expr
  | App of string * expr list
  | Rec of expr list
  | If of expr * expr * expr
  | Hole

and binop = ADD | MUL | SUB | DIV

exception SolverError of string

let rec expr_to_ir env = function
  | Arg i -> Kl_IR.Var i
  | Cst n -> Kl_IR.Cst n
  | Var s ->
    begin match List.assoc_opt s env with
    | Some e -> e
    | None -> raise (SolverError ("Unbound local name " ^ s))
    end
  | Arith (ADD, e1, e2) ->
    Kl_IR.(App (ADD, [expr_to_ir env e1; expr_to_ir env e2]))
  | Arith (SUB, e1, e2) ->
    Kl_IR.(App (SUB, [expr_to_ir env e1; expr_to_ir env e2]))
  | Arith (MUL, e1, e2) ->
    Kl_IR.(App (MUL, [expr_to_ir env e1; expr_to_ir env e2]))
  | Arith (DIV, e1, e2) ->
    Kl_IR.(App (DIV, [expr_to_ir env e1; expr_to_ir env e2]))
  | Show (e, r) ->
    Kl_IR.(App (OUT, [expr_to_ir env e; expr_to_ir env r]))
  | App (fname, args) ->
    Kl_IR.App (FUN fname, List.map (expr_to_ir env) args)
  | Rec args ->
    Kl_IR.App (SELF, List.map (expr_to_ir env) args)
  | If (e1, e2, e3) ->
    Kl_IR.If (expr_to_ir env e1, expr_to_ir env e2, expr_to_ir env e3)
  | Hole -> raise (SolverError "undetermined expressions remaining")

type constr =
  | Takes of int
  | Let of string * expr
  | Shows of expr
  | Uses of expr list
  | Returns of expr
  | Expects of expr * expr
  | Nothing

type declaration =
  | Function of string * string list * constr list
  | Constant of string * constr list
  | External of string * string list

type prog = declaration list


module Gamma = struct

  type 'a status =
    | Asserted of 'a
    | Unknown

  let merge_status x y =
    match x with
    | Unknown -> y
    | Asserted vx ->
      match y with
      | Unknown -> x
      | Asserted vy ->
        if vx = vy then x
        else raise (SolverError "inconsistent assumptions")

  type t = {
    n_args    : int status;
    locals    : (string * expr) list status;
    value     : expr status;
  }

  let set_args ctx n =
    { ctx with n_args = merge_status ctx.n_args (Asserted n) }
  
  let add_local ctx x v =
    match ctx.locals with
    | Unknown -> { ctx with locals = Asserted [x, v] }
    | Asserted l' ->
      match List.assoc_opt x l' with
      | Some _ -> raise (SolverError ("local value " ^ x ^ " already defined in context"))
      | None -> { ctx with locals = Asserted ((x, v)::l') }

  let (let*) = Option.bind

  let rec replace_hole (e : expr) (r : expr) =
    match e with
    | Show (x, Hole) -> Some (Show (x, r))
    | Show (x, res) ->
      let* res' = replace_hole res r in
      Some (Show (x, res'))
    | _ -> None

  let set_value ctx v =
    match ctx.value with
    | Unknown -> { ctx with value = Asserted v }
    | Asserted x ->
      match replace_hole x v with
      | Some x' -> { ctx with value = Asserted x' }
      | None -> raise (SolverError "Inconsistent return values")

  let empty : t =
    { n_args = Unknown
    ; locals = Unknown
    ; value  = Unknown
    }
end


let todo () =
  Printf.eprintf "not implemented yet !\n"; assert false

let solve_one (ctx : Gamma.t) (c : constr) =
  match c with
  | Takes n -> Gamma.set_args ctx n
  | Let (x, e) -> Gamma.add_local ctx x e
  | Shows x ->
    begin match ctx.value with
    | Asserted res -> { ctx with value = Asserted (Show (x, res)) }
    | Unknown -> { ctx with value = Asserted (Show (x, Hole)) }
    end
  | Uses _ -> todo ()
  | Returns x -> Gamma.set_value ctx x
  | Expects (_, _) -> todo ()
  | Nothing -> ctx

let solve (constraints : constr list) : Kl_IR.ast =
  let ctx = List.fold_left solve_one Gamma.empty constraints in
  match ctx.value with
  | Unknown -> raise (SolverError "No return value provided")
  | Asserted e ->
    let env : (string * Kl_IR.ast) list = match ctx.locals with
      | Unknown -> []
      | Asserted l ->
        List.fold_left (fun env (name, e) -> (name, expr_to_ir env e)::env) [] l
    in
    expr_to_ir env e

let compile (p : prog) : Kl_IR.ftable =
  List.map (function
    | External (name, _args) -> name, Kl_IR.Var 0
    | Constant (name, constraints) ->
      name, solve constraints
    | Function (name, args, constraints) ->
      name, solve (Takes (List.length args)::constraints)
  ) p