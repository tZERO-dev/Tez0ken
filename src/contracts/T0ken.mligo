#include "../partials/compliance/validate.mligo"

type balances = (address, nat) big_map

type storage = {
  symbol            : string;
  description       : string;
  owner             : address;
  issuer            : address;
  issuance_finished : bool;
  total_supply      : nat;
  balances          : balances;
  compliance        : address option;
}

type return = operation list * storage
let noops = ([] : operation list)

(* ------------------------------ Parameters -------------------------------- *)
type transfer_param = {
  destination : address;
  value : nat;
}

type override_param = {
  source : address;
  destination : address;
  value : nat;
}

type compliance_entry =
  | ValidateIssuance
  | ValidateTransfer
  | ValidateOverride

type access_parameter =
  | FinishIssuance of unit
  | IssueTokens of nat
  | SetCompliance of address option
  | Transfer of transfer_param
  | TransferOverride of override_param

(* -------------------------------- Helpers --------------------------------- *)
let compliance_for (entry, compliance : compliance_entry * address) : validate_param contract =
  match (
    match entry with
      | ValidateIssuance -> (Tezos.get_entrypoint_opt "%validateIssuance" compliance : validate_param contract option)
      | ValidateTransfer -> (Tezos.get_entrypoint_opt "%validateTransfer" compliance : validate_param contract option)
      | ValidateOverride -> (Tezos.get_entrypoint_opt "%validateOverride" compliance : validate_param contract option)
  ) with
    | Some contract -> contract
    | None -> (failwith "Invalid compliance" : validate_param contract)

let issuance_op (dst, value, compliance : address * nat * address) : operation =
  let param : validate_param = {source = Tezos.sender ; destination = dst ; value = value} in
  Tezos.transaction param 0tez (compliance_for (ValidateIssuance, compliance))

let transfer_op (src, dst, value, compliance : address * address * nat * address) : operation =
  let param : validate_param = {source = src ; destination = dst ; value = value} in
  Tezos.transaction param 0tez (compliance_for (ValidateTransfer, compliance))

let override_op (p, compliance : override_param * address) : operation =
  let param : validate_param = {source = p.source ; destination = p.destination ; value = p.value} in
  Tezos.transaction param 0tez (compliance_for (ValidateOverride, compliance))

let require_owner (store : storage) : bool =
  if Tezos.source <> store.owner then
    (failwith "Requires owner" : bool)
  else true

let require_issuer (store : storage) : bool =
  if Tezos.source <> store.issuer then
    (failwith "Requires issuer" : bool)
  else true

let require_can_issue (store : storage) : bool =
  if store.issuance_finished then
    (failwith "Issuance finished" : bool)
  else true

let balance_for (key, balances : address * balances) : nat =
  match Big_map.find_opt key balances with
    | Some i -> i
    | None -> 0n

let require_balance (src, value, balances : address * nat * balances) : nat =
  let b = balance_for (src, balances) in
  if b < value then
    (failwith "Insufficient funds" : nat)
  else b

let transfer_balances (src, dst, value, balances : address * address * nat * balances) : balances =
  let src_balance = abs (require_balance (src, value, balances) - value) in
  let dst_balance = balance_for (dst, balances) + value in
  Big_map.update dst (Some dst_balance) (Big_map.update src (Some src_balance) balances)

(* ------------------------------ Entrypoints ------------------------------- *)
let entry_Transfer (p, s : transfer_param * storage) : return =
  let s = {s with balances = transfer_balances (Tezos.sender, p.destination, p.value, s.balances)} in
  match s.compliance with
    | Some compliance ->
      if Tezos.sender = s.issuer then
        [issuance_op (p.destination, p.value, compliance)], s
      else
        [transfer_op (Tezos.sender, p.destination, p.value, compliance)], s
    | None -> noops, s

let entry_TransferOverride (p, s : override_param * storage) : return =
  let s = {s with balances = transfer_balances (p.source, p.destination, p.value, s.balances)} in
  match s.compliance with
    | Some compliance -> [override_op (p, compliance)], s
    | None -> (failwith "Overrides require compliance" : return)

let entry_IssueTokens (quantity, s : nat * storage) : return =
  let nil = require_issuer s && require_can_issue s in
  if quantity <= 0n then
    noops, s
  else
    let new_supply = s.total_supply + quantity in
    let new_balance = balance_for (s.issuer, s.balances) + quantity in
    let new_balances = Big_map.update s.issuer (Some new_balance) s.balances in
    noops, {s with total_supply = new_supply; balances = new_balances}

let entry_FinishIssuance (s : storage) : return =
  let nil = require_issuer s && require_can_issue s in
  noops, {s with issuance_finished = true}

let entry_SetCompliance (compliance, s : address option * storage) : return =
  let nil = require_owner s in
  noops, {s with compliance = compliance}

(* --------------------------------- Access --------------------------------- *)
let access (action, s : access_parameter * storage) : return =
  match action with
    | FinishIssuance -> entry_FinishIssuance (s)
    | IssueTokens q -> entry_IssueTokens (q, s)
    | SetCompliance c -> entry_SetCompliance (c, s)
    | Transfer t -> entry_Transfer(t, s)
    | TransferOverride t -> entry_TransferOverride (t, s)
