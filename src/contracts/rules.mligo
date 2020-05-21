#include "../partials/compliance/validate.mligo"

type rules = address list

type storage = {
  admin : address;
  registry : address;
  rules : rules;
}

type return = operation list * storage

type access_parameter =
  | ValidateRules of validate_response
  | SetRules of rules

let rule_op (rule_address, param : address * validate_response) : operation =
  let rule : validate_response contract =
    match (Tezos.get_contract_opt rule_address : validate_response contract option) with
      | Some contract -> contract
      | None -> (failwith "InvalidRule" : validate_response contract) in
  Tezos.transaction param 0tez rule

let access (action, s : access_parameter * storage) : return =
  match action with
    | ValidateRules p ->
        if Tezos.sender <> s.registry then
          (failwith "InvalidSender" : return)
        else if p.accounts.0.frozen || p.accounts.1.frozen then
          (failwith "FrozenAccount" : return)
        else if p.issuance then
          ([] : operation list), s
        else
          (List.map (fun (rule : address) -> rule_op (rule, p)) s.rules), s
    | SetRules r ->
        if Tezos.source <> s.admin then
          (failwith "NotAllowed" : return)
        else
          ([] : operation list), {s with rules = r}
