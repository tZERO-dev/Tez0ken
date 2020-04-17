#include "../partials/registry/accounts.mligo"
#include "../partials/compliance/validate.mligo"

type accounts = (address, account) big_map

type storage = {
  accounts: accounts;
}

let admin = 1n
let custodian = 2n
let custodial = 3n
let broker = 4n
let investor = 5n
let extrinsic = 6n

let permissions = Map.literal [
  (admin, admin);
  (custodian, admin);
  (custodial, custodian);
  (broker, custodian);
  (investor, broker);
  (extrinsic, admin);
]

type return = operation list * storage
let noops = ([] : operation list)

(* ------------------------------ Parameters -------------------------------- *)
type new_param = {
  address : address;
  role : nat;
  frozen : bool;
  domicile : string;
  accreditation : nat option;
}

type freeze_param = {
  address : address;
  frozen : bool;
}

type accreditation_param = {
  address : address;
  accreditation : nat option
}

type domicile_param = {
  address : address;
  domicile : string;
}

type access_parameter =
  | Accounts of validate_request
  | Append of new_param
  | Exists of address
  | Remove of address
  | SetAccreditation of accreditation_param
  | SetDomicile of domicile_param
  | SetFrozen of freeze_param

(* -------------------------------- Helpers --------------------------------- *)
let find (a, s : address * storage) : account =
  match Big_map.find_opt a s.accounts with
    | Some a -> a
    | None -> (failwith "Invalid address" : account)

let find_unfrozen (p, s : address * storage) : account =
  let a = find (p, s) in
  if a.frozen then
    (failwith "Frozen account" : account)
  else
    a

let child_for (p, s : address *  storage) : account =
  let parent = find_unfrozen (Tezos.sender, s) in
  let child = find (p, s) in
  if parent.role <> admin && child.parent <> Tezos.sender then
    (failwith "Invalid parent" : account)
  else
    child

(* ------------------------------ Entrypoints ------------------------------- *)
let entry_Accounts (p, s : validate_request * storage) : return =
  let src = find (p.request.source, s) in
  let dst = find (p.request.destination, s) in
  let callback : validate_response = {request = p.request ; source = src ; destination = dst} in
  [Tezos.transaction callback 0mutez p.callback], s

let entry_Append (p, s : new_param * storage) : return =
  let parent = find_unfrozen (Tezos.sender, s) in
  if parent.role = Map.find p.role permissions <> true then
    (failwith "Invalid role" : return)
  else
    let a : account = {
      parent = Tezos.sender ;
      role = p.role ;
      frozen = p.frozen ;
      accreditation = p.accreditation ;
      domicile = p.domicile ;
    } in
    match Big_map.find_opt p.address s.accounts with
      | Some existing ->
        if existing.parent <> Tezos.sender then
          (failwith "Already exists" : return)
        else
          noops, {s with accounts = Big_map.update p.address (Some a) s.accounts}
      | None ->
		noops, {s with accounts = Big_map.add p.address a s.accounts}

let entry_Exists (p, s : address * storage) : return =
  let a = find (p, s) in
  noops, s

let entry_Remove (p, s : address * storage) : return =
  let parent = find_unfrozen (Tezos.sender, s) in
  let child = find (p, s) in
  if child.parent <> Tezos.sender then
    (failwith "Invalid parent" : return)
  else
    noops, {s with accounts = Big_map.remove p s.accounts}

let entry_SetAccreditation (p, s : accreditation_param * storage) : return =
  let child = child_for (p.address, s) in
  noops, {s with accounts = Big_map.update p.address (Some {child with accreditation = p.accreditation}) s.accounts}

let entry_SetDomicile (p, s : domicile_param * storage) : return =
  let child = child_for (p.address, s) in
  noops, {s with accounts = Big_map.update p.address (Some {child with domicile = p.domicile}) s.accounts}

let entry_SetFrozen (p, s : freeze_param * storage) : return =
  let child = child_for (p.address, s) in
  noops, {s with accounts = Big_map.update p.address (Some {child with frozen = p.frozen}) s.accounts}

(* --------------------------------- Access --------------------------------- *)
let access (action, store : access_parameter * storage) : return =
  match action with
    | Accounts p -> entry_Accounts(p, store)
    | Append p -> entry_Append(p, store)
    | Exists p -> entry_Exists(p, store)
    | Remove p -> entry_Remove(p, store)
    | SetAccreditation p -> entry_SetAccreditation(p, store)
    | SetDomicile p -> entry_SetDomicile(p, store)
    | SetFrozen p -> entry_SetFrozen(p, store)
