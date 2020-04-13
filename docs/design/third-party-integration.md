# Third-Party Integration

## Token Contract
To create your own token using tZERO's scurity token implementation, clone or fork [T0ken.mligo](src/contracts/T0ken.mligo)
and deploy, matching the following origination values with your own:

```
 - symbol       : string;         (* Ticker - COMPA                               *)
 - description  : string;         (* Company A Preferred                          *)
 - owner        : address;        (* Contract owner address                       *)
 - issuer       : address;        (* Security issuer address                      *)
 - total_supply : nat;            (* Total supply of tokens                       *)
 - compliance   : address option; (* The address compliance, to enforce transfers *)
```
If you're linking to your own, yet undeployed compliance, this can be excluded and set in the next step.

## Compliance Contract
The next contract that will need to be deployed, and linked to, is the [Compliance](src/contracts/compliance.mligo) contract.
The compliance contract has the entrypoints: `ValidateIssuance`, `ValidateTransfer`, `ValidateOverride`, used to
terminate issuance, transfers and overrides that do not satisfy compliance rules.

To link a token contract to this newly deployed compliance, use the entrypoint `SetCompliance`, of the token, passing
the address of compliance.

Compliance rules can be set through the entrypoint `SetRules`, which takes an `address list`.
_i.e_

```
SetRules([("KT1Fc7XHbZhpd8wkYvzSJnAj37GxNyqSsHhZ" : address)])
```

## Registry Contract
Also, to take care of on-boarding and KYC of investors, you can link to and use the `registry.mligo` contract, used by
tZERO, by referencing the it, in any newly created compliance through the entrypoint `SetRegistry`.
This method takes the address of the registry contract as the parameter. tZERO's public storage contract address is
`Coming soon`

Although unnecessary, you can deploy your own registry, linking the compliance from the prior setup, to your own.
