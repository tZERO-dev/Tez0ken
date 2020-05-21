(* NOTE: FA1.2 Implementation Details
 *
 * Please see `/src/partials/token/fa12.mligo` for details.
 *
 * To correctly implement FA1.2 errors, we must modify the compiled Michelson of this contract, as LIGO only supports
 * `string`, `int`, and `nat` error types, while FA1.2 specifies an error as a pair of
 * (nat :required, nat :present), with the message.
 *
 * To implement the errors, modify the compiled contract to match the below:
 * 
 * !!!Any changes to the this contract, or changes in the LIGO compiler, may require re-writting the below Michelson!!!
 *
------------------------------------------------------------------------------------------------------------------------

61     |     CDR ;
62     |     DIG 1 ;
63     |     DUP ;
64     |     DUG 2 ;
65     |     COMPARE ;
66     |     LT ;
67   R |     IF { DIG 2 ; CDR ; PAIR ; PUSH string "NotEnoughBalance" ; PAIR ; FAILWITH }
68     |        { DIG 1 ;
69     |          DUP ;
70     |          DUG 2 ;
71     |          DIG 3 ;
72     |          DUP ;
73     |          DUG 4 ;
...
...
171    |                              CDR ;
172    |                              DIG 3 ;
173    |                              DUP ;
174    |                              DUG 4 ;
175    |                              GET ;
176    |                              IF_NONE { PUSH nat 0 } { DUP ; DIP { DROP } } ;
177  N |                              DUP ; DUG 3;
178    |                              COMPARE ;
179    |                              GT ;
180    |                              AND ;
181  R |                              IF { PUSH string "UnsafeAllowanceChange" ; PAIR ; FAILWITH }
182  R |                                 { DROP ; DIG 5 ;
183    |                                   DUP ;
184    |                                   DUG 6 ;
185    |                                   DIG 6 ;
186    |                                   DUP ;
187    |                                   DUG 7 ;
188    |                                   CAR ;
...
...
791    |                                   CDR ;
792    |                                   DIG 1 ;
793    |                                   DUP ;
794    |                                   DUG 2 ;
795    |                                   GET ;
796    |                                   IF_NONE
797  R |                                     { SWAP ; CDR ; PUSH nat 0 ; SWAP ; PAIR ; PUSH string "NotEnoughAllowance" ; PAIR ; FAILWITH }
798    |                                     { DIG 2 ;
799    |                                       DUP ;
800    |                                       DUG 3 ;
801    |                                       CDR ;
802    |                                       DIG 1 ;
803    |                                       DUP ;
804    |                                       DUG 2 ;
805    |                                       COMPARE ;
806    |                                       LT ;
807  R |                                       IF { DIG 2 ; CDR ; PAIR ; PUSH string "NotEnoughAllowance" ; PAIR ; FAILWITH }
808    |                                          { DIG 7 ;
809    |                                            DUP ;
810    |                                            DUG 8 ;
811    |                                            DIG 8 ;
812    |                                            DUP ;
813    |                                            DUG 9 ;

------------------------------------------------------------------------------------------------------------------------
    R - Replace
    N - New/Insert
 *)

#include "../partials/token/fa12.mligo"
#include "../partials/compliance/validate.mligo"


(* (owner * spender, allowance) *)
type allowances = (address * address, nat) big_map
type balances = (address, nat) big_map

type storage = {
  admins : address set;
  issuer : address;
  symbol : string;
  description : string;
  total_supply : nat;
  issuance_finished : bool;
  allowances : allowances;
  balances : balances;
  registry : address;
  rules : address;
  paused : bool;
}

type return = operation list * storage

type access_parameter =
  | Approve of approve_param
  | FinishIssuance of unit
  | GetAllowance of allowance_param
  | GetBalance of balance_param
  | GetTotalSupply of unit * nat contract
  | IssueTokens of nat
  | SetAdmin of address
  | SetIssuer of address
  | SetPaused of bool
  | SetRegistry of address
  | SetRules of address
  | Transfer of transfer_param_michelson
  | TransferOverride of transfer_param_michelson

let validate_account_op (registry, param : address * address) : operation =
  match (Tezos.get_entrypoint_opt "%validateAccount" registry : address contract option) with
    | Some r -> Tezos.transaction param 0tez r
    | None -> (failwith "InvalidRegistry" : operation)

let validate_transfer_op (registry, param : address * validate_param) : operation =
  match (Tezos.get_entrypoint_opt "%validateAccounts" registry : validate_param contract option) with
    | Some r -> Tezos.transaction param 0tez r
    | None -> (failwith "InvalidRegistry" : operation)

let balance_for (key, balances : address * balances) : nat =
  match Big_map.find_opt key balances with
    | Some i -> i
    | None -> 0n

let transfer_balances (p, total_supply, b : transfer_param * nat * balances) : nat * nat * balances =
  let grantor_balance = balance_for (p.grantor, b) in
  if grantor_balance < p.value then
    (failwith "NotEnoughBalance" : nat * nat * balances)
  else
    let b = Big_map.update p.grantor (Some (abs (grantor_balance - p.value))) b in
    let receiver_balance = balance_for (p.receiver, b) in
    grantor_balance, receiver_balance, Big_map.update p.receiver (Some (receiver_balance + p.value)) b

let access (action, s : access_parameter * storage) : return =
  match action with
    | Approve p ->
        if s.paused then
          (failwith "Paused" : return)
        else
          let key = (Tezos.source, p.spender) in
          let allowance = match Big_map.find_opt key s.allowances with
            | Some value -> value
            | None -> 0n in
          if allowance > 0n && p.value > 0n then
            (failwith "UnsafeAllowanceChange" : return)
          else
            ([] : operation list), {s with allowances = Big_map.update key (Some p.value) s.allowances}
    | FinishIssuance ->
        if s.paused then
          (failwith "Paused" : return)
        else if Tezos.source <> s.issuer || s.issuance_finished then
          (failwith "NotAllowed" : return)
        else
          ([] : operation list), {s with issuance_finished = true}
    | GetAllowance p ->
        let allowance = match Big_map.find_opt (p.owner, p.spender) s.allowances with
          | Some n -> n
          | None -> 0n in
        [Tezos.transaction allowance 0tez p.yield], s
    | GetBalance p ->
        [Tezos.transaction (balance_for (p.owner, s.balances)) 0tez p.yield], s
    | GetTotalSupply p ->
        [Tezos.transaction s.total_supply 0tez p.1], s
    | IssueTokens value ->
        if s.paused then
          (failwith "Paused" : return)
        else if Tezos.source <> s.issuer || s.issuance_finished then
          (failwith "NotAllowed" : return)
        else
          if value <= 0n then
            ([] : operation list), s
          else
            ([] : operation list), {s with
              total_supply = s.total_supply + value;
              balances = Big_map.update s.issuer (Some (balance_for (s.issuer, s.balances) + value)) s.balances}
    | SetAdmin admin ->
        if Set.mem Tezos.source s.admins = false then
          (failwith "NotAllowed" : return )
        else if Set.mem admin s.admins then
          if Set.size s.admins = 1n then
            (failwith "SoloAdmin" : return)
          else
            ([] : operation list), {s with admins = Set.remove admin s.admins}
        else
          ([] : operation list), {s with admins = Set.add admin s.admins}
    | SetIssuer issuer ->
        if Set.mem Tezos.source s.admins = false then
          (failwith "NotAllowed" : return )
        else
          ([] : operation list), {s with issuer = issuer}
    | SetPaused paused ->
        if Set.mem Tezos.source s.admins = false then
          (failwith "NotAllowed" : return )
        else
          ([] : operation list), {s with paused = paused}
    | SetRegistry registry ->
        if Set.mem Tezos.source s.admins = false then
          (failwith "NotAllowed" : return )
        else
          ([] : operation list), {s with registry = registry}
    | SetRules rules ->
        if Set.mem Tezos.source s.admins = false then
          (failwith "NotAllowed" : return)
        else
          ([] : operation list), {s with rules = rules}
    | Transfer p ->
        if s.paused then
          (failwith "Paused" : return)
        else
          let p : transfer_param = Layout.convert_from_right_comb p in
          let s = (
            if p.grantor <> Tezos.source then
              let key = (p.grantor, Tezos.source) in
              match Big_map.find_opt key s.allowances with
                | Some allowance ->
                    if allowance < p.value then
                      (failwith "NotEnoughAllowance" : storage)
                    else
                      {s with allowances = Big_map.update key (Some (abs (allowance - p.value))) s.allowances}
                | None -> (failwith "NotEnoughAllowance" : storage)
            else
              s
          ) in
          let grantor_balance, receiver_balance, balances = transfer_balances (p, s.total_supply, s.balances) in
          let param : validate_param = {
            addresses = p.grantor, p.receiver;
            balances = grantor_balance, receiver_balance;
            values = p.value, s.total_supply;
            issuance = Tezos.source = s.issuer && Tezos.source = p.grantor;
            yield = (match (Tezos.get_entrypoint_opt "%validateRules" s.rules : validate_response contract option) with
              | Some rules -> rules
              | None -> (failwith "InvalidRules" : validate_response contract));
          } in
          [validate_transfer_op (s.registry, param)], {s with balances = balances}
    | TransferOverride p ->
        if Set.mem Tezos.source s.admins = false then
          (failwith "NotAllowed" : return )
        else
          let p : transfer_param = Layout.convert_from_right_comb p in
          let _, _, balances = transfer_balances (p, s.total_supply, s.balances) in
          [validate_account_op (s.registry, p.receiver)], s
