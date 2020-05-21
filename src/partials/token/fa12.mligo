(*
 * NOTE: FA1.2 Implementation Details
 * ----------------------------------
 *
 * There exists a few conflicts while implementing FA1.2 within LIGO:
 *
 *   1. FA1.2 specifies annotation naming that conflicts with some languages
 *      and compilers. Simply adding an underscore suffix isn't an option, as
 *      the underscore still exists in the compiled contract.
 *      (for instance: `to` is a keyword in LIGO and `from` is a keyword in Python)
 *
 *   2. LIGO currently compiles records into pairs, ordered alphabetically by their
 *      corresponding names. This results in pair orderings that don't match
 *      that of the standard.
 *
 * The following has been implemented to work around the above issues with the spec:
 *
 *   1. Synonyms have been chosen in place of the naming standards, and a
 *      post-compilation process renames these annotations to their corresponding
 *      FA1.2 values.
 *
 *   2. The above synonyms have been chosen based on their alphabetic significance,
 *      resulting in correctly ordered pairs.
 *
 *
 * In addition to the above, the FA1.2 `transfer` specifies a pair that LIGO doesn't
 * compile to, without some additional work.
 * The following is the FA1.2 specification for `transfer`:
 *
 *   (address :from, (address :to, nat :value))
 *
 * LIGO compiles our record, after annotation renaming, into:
 *
 *   (pair %transfer (pair (address %from) (address %to)) (nat %value))))
 *
 * which translates to:
 *
 *    ((address :from, address :to), nat :value)
 *
 * The `transfer_param_michelson` type, below, orders the values to match that of the spec.
 * This gets reversed in `t0ken.mligo`, giving the correct ordering with:
 *
 *   Layout.convert_from_right_comb
 *
 * The last issue is with the errors of FA1.2/FA1.
 * From the FA1 spec:
 *
 *   The error must contain a (nat :required, nat :present) pair
 *
 * LIGO only supports a single arg to `failwith`, and must be one of `int`, `nat`, or `string`
 * The only workaround for this is to hand write Michelson within the compiled contracts.
 * Please see the comments in `/src/contracts/t0ken.mligo` for more information.
 *)

type transfer_param = {
  grantor : address;     (* renamed to `from` in post-compilation *)
  receiver : address;    (* renamed to `to`   in post-compilation *)
  value : nat;
}

type transfer_param_michelson = transfer_param michelson_pair_right_comb

type approve_param = {
  spender : address;
  value : nat;
}

type  allowance_param = {
  owner : address;
  spender : address;
  yield : nat contract;  (* renamed to `callback` in post-compilation *)
}

type balance_param = {
  owner : address;
  yield : nat contract;  (* renamed to `callback` in post-compilation *)
}
