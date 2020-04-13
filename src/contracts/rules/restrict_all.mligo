#include "../../partials/compliance/validate.mligo"

let access (p, s : validate_response * unit) : operation list * unit =
  (failwith "Transfer failed at rule: RestrictAll" : operation list * unit)
