# T0ken Contract
The token contract which represents the security to be traded is an [FA1.2][fa1.2] implementation, providing flexibility
for the token to be used within other, and future, trading platforms.

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

This document walks through the LIGO code for the token contract [t0ken.mligo](../../src/contracts/t0ken.mligo) and
uses "Company A Preferred Stock" as an example company that is attempting to implement security tokens for offering
equities (in this case, Company A Preferred Stock).

## Definition
The Token contract is the main contract that handles the base methods in the tZERO security token ecosystem.

![Token Design Diagram][design]  


[fa1.2]: https://gitlab.com/tzip/tzip/-/blob/master/proposals/tzip-7/tzip-7.md
[bill-69]: //legis.delaware.gov/json/BillDetail/GenerateHtmlDocument?legislationId=25730&legislationTypeId=1&docTypeId=2&legislationName=SB69
[title-8]: //legis.delaware.gov/json/BillDetail/GenerateHtmlDocument?legislationId=25730&legislationTypeId=1&docTypeId=2&legislationName=SB69
[design]: http://www.plantuml.com/plantuml/png/dLJ1Jjj043t7Nx62GnqA5LHjKIk422cfEBLASaTZUnAlijwrPiT4AUNVwzq49zwOe3OdvxtTUU-DPtnZ6OYhGaNln77NJqnufT1sav5TI5q2GI5i3fbPIZqNCr0MTvWIqWNCKJn5lSHGXZGqof0uFZyVtbr-ZtepexaDFU_SbfgHPf3w-q1abi7rf2u_9rFfR4CCBqTVxxuS49l8toWkFhTaXf9IXTam1uAKaPpQOMEf0cjVCvKZrDgthreBY6Kk6Tzst6Mf1ymaaufnTDYkAKgZKRDuUbE_WRh21IP2avzgrLncAB0eUIKAvDnaratNF_-YQFloZqQ3YmyVZyJLbOZlJxsvlhY-Tc7UYoc1jZCa4VFcwS67xZjoK9Pa7b74i7xOeNuW3vGoImsfuzqZw3GuSGiAjECJKFlir32eILMMQYNYIaiM9q83YzHeTfFKhziHlMp0z7o1keumnfH1pnMk0snJjktxiEDss5frHgOGtmHa6Q6r7c8J08-WAgmn3HprdgDTZLOREYLiYJf3QfKyKB3fsq7NTPUH0fUDK0jDGIate3MysybGDW7rFwA7o_kbRjxJS5smAGTP8RNTrXCMsHFIsce_tQf8ZAf1ooJrt6CPsfHaoTBeDi5kZXxiUf2yiwQmJpcJMjeSivfBZ56UR1hlBCKldavUJ9owAdsHoFb30QM_aO0AptUS8fnBoxGAyb2bq0PO2PNTclBGo3kztnWNST-ZxZzEpGAr5R5JzEW4UU1wshXfO7-Uzl5VQy7OwJNWU6Du__ZOUMx3pTVYvoCIoGmxlXhFRclz5qTS_JaxMmz450NhQHgcsQaGRrOZP19GdVWDwgmgr5y0
