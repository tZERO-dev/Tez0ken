#include "../partials/compliance/validate.mligo"

type rules = address list

type storage = {
  owner : address;
  token : address;
  registry : address;
  rules : rules;
}

type return = operation list * storage
let noops = ([] : operation list)

type access_parameter =
  | Rules of validate_response
  | SetRegistry of address
  | SetRules of rules
  | ValidateIssuance of validate_param
  | ValidateOverride of validate_param
  | ValidateTransfer of validate_param

(* -------------------------------- Helpers --------------------------------- *)
let accounts_op (registry_address, param : address * validate_param) : operation =
  let registry : validate_request contract =
    match (Tezos.get_entrypoint_opt "%accounts" registry_address : validate_request contract option) with
      | Some contract -> contract
      | None -> (failwith "Invalid registry" : validate_request contract) in

  let callback : validate_response contract = Tezos.self("%rules") in
  let get_accounts : validate_request = {request = param ; callback = callback} in
  Tezos.transaction get_accounts 0tez registry

let rule_op (rule_address, param : address * validate_response) : operation =
  let rule : validate_response contract =
    match (Tezos.get_contract_opt rule_address : validate_response contract option) with
      | Some contract -> contract
      | None -> (failwith "Invalid rule" : validate_response contract) in

  Tezos.transaction param 0tez rule

let whitelist_op (registry_address, a : address * address) : operation =
  let registry : address contract =
    match (Tezos.get_entrypoint_opt "%exists" registry_address : address contract option) with
      | Some contract -> contract
      | None -> (failwith "Invalid registry" : address contract) in

  Tezos.transaction a 0tez registry

(* ------------------------------ Entrypoints ------------------------------- *)
let entry_Rules (p, s : validate_response * storage) : return =
  if Tezos.sender <> s.registry then
    (failwith "Invalid sender" : return)
  else if p.source.frozen || p.destination.frozen then
    (failwith "Source and/or destination frozen" : return)
  else
    (List.map (fun (rule : address) -> rule_op (rule, p)) s.rules), s

let entry_SetRegistry (registry, s : address * storage) : return =
  if Tezos.source <> s.owner then
    (failwith "Not allowed" : return)
  else
    noops, {s with registry = registry}

let entry_SetRules (r, s : rules * storage) : return =
  if Tezos.source <> s.owner then
    (failwith "Not allowed" : return)
  else
    noops, {s with rules = r}

let entry_Issuance (p, s : validate_param * storage) : return =
  [(whitelist_op (s.registry, p.destination))], s

let entry_Override (p, s : validate_param * storage) : return =
  if Tezos.source <> s.owner then
    (failwith "Not allowed" : return )
  else
    [whitelist_op (s.registry, p.destination)], s

let entry_Transfer (p, s : validate_param * storage) : return =
  if Tezos.sender <> s.token then
    (failwith "Invalid sender" : return )
  else
    [(accounts_op (s.registry, p))], s

(* --------------------------------- Access --------------------------------- *)
let access (action, store : access_parameter * storage) : return =
  match action with
    | Rules p -> entry_Rules(p, store)
    | SetRegistry p -> entry_SetRegistry(p, store)
    | SetRules p -> entry_SetRules(p, store)
    | ValidateIssuance p -> entry_Issuance(p, store)
    | ValidateOverride p -> entry_Override(p, store)
    | ValidateTransfer p -> entry_Transfer(p, store)
