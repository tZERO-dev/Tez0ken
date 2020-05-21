#include "../../partials/compliance/validate.mligo"

let access (p, s : validate_response * unit) : operation list * unit =
  if p.accounts.1.domicile = "US" && p.accounts.0.domicile <> "US" then
    (failwith "Reg-S cannot transfer to Reg-D" : operation list * unit)
  else
    ([] : operation list), ()
