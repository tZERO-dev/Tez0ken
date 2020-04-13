# T0ken Contract
The token contract which represents the security to be traded is an ERC-20-like implementation, providing flexibility for the token to be used within other, and future, trading platforms.

The token contract is also compliant with [Delaware Senate Bill 69][bill-69] and [Title 8][title-8] of Delaware Code
relating to the General Corporation Law, supporting the following Title 8 requirements:.

- Token owners must have their identity verified (KYC).
- Must provide the following three functions of a “Corporations Stock Ledger” (Section 224 of the act).
  - Enable the corporation to prepare the list of shareholders, specified in Sections 219 and 220 of the act.
  - Record “Partly Paid Share,” “Total Amount Paid,” “Total Amount to be Paid,” specified in Sections 156, 159, 217(a) and 218 of the act.
  - Record transfers of shares, specified in Section 159 of the act.
- Require that each token corresponds to a single share (i.e. no partial tokens).
- Provide a way to re-issue tokens to a new address, cancelling the current one.
- Provide a way to recover shares by moving them to a new address, invalidating current one. (Section 167)

This document walks through the LIGO code for the token contract [T0ken.mligo](../../src/contracts/T0ken.mligo) and
uses "Company A Preferred Stock" as an example company that is attempting to implement security tokens for offering
equities (in this case, Company A Preferred Stock).

## Definition
The Token contract is the main contract that handles the base methods in the tZERO security token ecosystem.

![Token Design Diagram][design]  


[ERC-20]: //theethereum.wiki/w/index.php/ERC-20_Token_Standard
[bill-69]: //legis.delaware.gov/json/BillDetail/GenerateHtmlDocument?legislationId=25730&legislationTypeId=1&docTypeId=2&legislationName=SB69
[title-8]: //legis.delaware.gov/json/BillDetail/GenerateHtmlDocument?legislationId=25730&legislationTypeId=1&docTypeId=2&legislationName=SB69
[design]: http://www.plantuml.com/plantuml/png/ZPD1Qzj048NFqQyOoA4ExS65jg4bX50rXfuAiUzcfHrRYrUxOcOKumR_zwnN3be5HNXFqhpPzxuHemSMHTBMDli4rsC7bdAmoEDYnZlZ6aMg1gwKzdlZjh1HbZ5H6bNkr1RX9GCeF6cat5jFS3sVvu-tVq9ruvqCQyVald62j55bvw28_FwzGH4YjkHRfyzAVhlu-VXZCd1f_YDy_Jw8oWsL5dLUXRSofCR4QRhIAkQFoIfK8V_tntplb7rb12_X7WK3K29aYbPmCKtjwyOxT08l5qB4skYKuoG9wxSGNHcDW7KZ1wXHAgyvMRZBJvRrso2a76-Grjr8TtSmU_eICM_W_ZuEzXaqiXYdn7W7lq1fJSWSbMTbMmor86R7rDS_8r70dVHbtrA9GylBmzv-YPNVeGi9JrYASbkBqV-gswdLl1FpBhoBZYS27Eh2ss39GiPj4oLGb6IQI34Y-xr3wl4InJ2t4v9o9QutnXckK8UkmdkRj8WNPTVSDeqzT9CcOg7iwJe7uUsnL-CsMdEgzk7WumHPqhQ8sN_FA32xIRHJ5UFdvA6mHCbx-zdGFMrSdTS9PiF56klvTruHc2NB4dklZjanUq2dszg-0W00
