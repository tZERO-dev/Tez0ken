#include "../partials/registry/accounts.mligo"
#include "../partials/compliance/validate.mligo"

type accounts = (address, account) big_map

let admin = 1n
let issuer = 2n
let custodian = 3n
let custodial = 4n
let broker = 5n
let investor = 6n
let extrinsic = 7n

let permissions = Map.literal [
  (admin, admin);
  (issuer, admin);
  (custodian, admin);
  (custodial, custodian);
  (broker, custodian);
  (investor, broker);
  (extrinsic, admin);
]

type return = operation list * accounts

type account_param = {
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
  | Append of account_param
  | ValidateAccount of address
  | ValidateAccounts of validate_param
  | Remove of address
  | SetAccreditation of accreditation_param
  | SetDomicile of domicile_param
  | SetFrozen of freeze_param

let find (a, s : address * accounts) : account =
  match Big_map.find_opt a s with
    | Some a -> a
    | None -> (failwith "InvalidAddress" : account)

let find_unfrozen (p, s : address * accounts) : account =
  let a = find (p, s) in
  if a.frozen then
    (failwith "FrozenAccount" : account)
  else
    a

let child_for (p, s : address *  accounts) : account =
  let parent = find_unfrozen (Tezos.sender, s) in
  let child = find (p, s) in
  if parent.role <> admin && child.parent <> Tezos.sender then
    (failwith "InvalidParent" : account)
  else
    child

let access (action, s : access_parameter * accounts) : return =
  match action with
    | Append p ->
        let parent = find_unfrozen (Tezos.sender, s) in
        if parent.role = Map.find p.role permissions <> true then
          (failwith "InvalidRole" : return)
        else
          let a : account = {
            parent = Tezos.sender ;
            role = p.role ;
            frozen = p.frozen ;
            accreditation = p.accreditation ;
            domicile = p.domicile ;
          } in
          (match Big_map.find_opt p.address s with
            | Some existing ->
                if existing.parent <> Tezos.sender then
                  (failwith "Exists" : return)
                else
                  ([] : operation list), Big_map.update p.address (Some a) s
            | None ->
                ([] : operation list), Big_map.add p.address a s)
    | ValidateAccount p ->
        let a = find (p, s) in
        ([] : operation list), s
    | ValidateAccounts p ->
        let param = {
          accounts = find (p.addresses.0, s), find (p.addresses.1, s);
          addresses = p.addresses;
          balances = p.balances;
          values = p.values;
          issuance = p.issuance;
          sender = Tezos.sender;
        } in
        [Tezos.transaction param 0tez p.yield], s
    | Remove p ->
        let parent = find_unfrozen (Tezos.sender, s) in
        let child = find (p, s) in
        if child.parent <> Tezos.sender then
          (failwith "InvalidParent" : return)
        else
          ([] : operation list), Big_map.remove p s
    | SetAccreditation p ->
        let child = child_for (p.address, s) in
        ([] : operation list), Big_map.update p.address (Some {child with accreditation = p.accreditation}) s
    | SetDomicile p ->
        let child = child_for (p.address, s) in
        ([] : operation list), Big_map.update p.address (Some {child with domicile = p.domicile}) s
    | SetFrozen p ->
        let child = child_for (p.address, s) in
        ([] : operation list), Big_map.update p.address (Some {child with frozen = p.frozen}) s
