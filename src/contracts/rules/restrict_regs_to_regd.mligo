#include "../../partials/compliance/validate.mligo"

let access (p, s : validate_response * unit) : operation list * unit =
  if p.destination.domicile = "US" && p.source.domicile <> "US" then
    (failwith "Reg-S cannot transfer to Reg-D" : operation list * unit)
  else
    ([] : operation list), ()
