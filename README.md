[<img src="https://storage.googleapis.com/media.tzero.com/t0ken/logo.png" width="400px" />](https://www.tzero.com/)

---
*Note: this software is currently in alpha*

# The Trading Platform
The trading platform is a regulatory-compliant suite of smart contracts serving as an Alternative Trading Solution (ATS)
that allows trading and fast settlement of securities in t-0 time. Built on the Ethereum chain, the platform provides
secure, fault-tolerant, transparent, and fast transaction settlement while being compliant to regulatory requirements.

The platform provides methods for issuance of security tokens which can be customized to represent various types of
securities. The security tokens are compliant with Delaware General Corporate Law, [Title 8][Title 8].

This project describes the set of Tezos contracts that represent tZERO's token and trading functionality. See below
for instructions and walk-throughs for third-party integration and customization.

## Components
For a token to be tradable, it first has to be defined, created and then be constrained within the set of regulatory
rules to ensure compliance with the trading laws for the parties involved (investors, broker-dealers, and custodians).

The tokens are created and their trades validated within the following interrelated set of components:
 - [Token](docs/design/token.md)
 - [Registry](docs/design/registry.md)
 - [Compliance](docs/design/compliance.md)

![Detailed Design Diagram][uml-overall]

### T0ken
The token contract defines and creates the tokens representative of the securities to be traded.

*See the [Token contract](docs/design/token.md) page for in-depth details.*

### Registry
The registry maintains groupings of investor, broker-dealer, and custodian accounts that define and coordinate
the behavior of these interacting entities.

*See the [Registry](docs/design/registry.md) page for in-depth details.*

### Compliance
The compliance contracts maintain the set of trade rules and exemptions (e.g. [Reg A][reg-a], [Reg D][reg-d],
etc.) allowing valid trades, while halting improper ones from taking place.

*See the [Compliance](docs/design/compliance.md) page for in-depth details.*

## Third-Party Integration
*See the [Third Party Integration](./docs/design/third-party-integration.md) page for in-depth details.*

## Developer

This repo contains only the LIGO contracts, all other files _(including tests, tools, etc.)_ have been excluded, for now.  
We'll be providing all other files in the future, but for now this allows anyone to use the contracts.

We have included a `Makefile`, which relies on [Docker](https://www.docker.com/get-started), if you just want to compile the contracts into Michelson

To build, simply run:

```
% make
```

This will create the `build/` folder with all Michelson/`.tz` files.

## License
This project is licensed under the [Apache 2.0][apache 2.0] license.

## Links
 - [tZERO's Website](https://www.tzero.com/)


[fa1.2]: https://gitlab.com/tzip/tzip/-/blob/master/proposals/tzip-7/tzip-7.md
[T-plus-N]: //www.investopedia.com/terms/t/tplus1.asp
[Title 8]: //legis.delaware.gov/json/BillDetail/GenerateHtmlDocument?legislationId=25730&legislationTypeId=1&docTypeId=2&legislationName=SB69
[reg-a]: //www.sec.gov/smallbusiness/exemptofferings/rega
[reg-d]: //www.sec.gov/fast-answers/answers-regdhtm.html
[apache 2.0]: //www.apache.org/licenses/LICENSE-2.0.html
[uml-overall]: http://www.plantuml.com/plantuml/png/hP91xvem6CRl_HHlyF0_OLoopPaiYnCqsLMNx60uLFgYXDAQjiounUy-MgaWWyC_aOE1vtruVW_sNMf3bQbAJjvWCdJ1pbmvwk4XqKKkpbJH4hwdHggLL0nL9BbKC9dDelKy_iz2q-AeP2NOtVRhb1licpPIcD4KRt35u20vwqprYJ9voSKHCifrDrX8Xl2N01nw3IRnOlDb7Td9G7s0pBBoFmWVFZLFpuvR1yAeeGUgHq3HVBDOVtu9AAj_HYZfF5lWQoYfBCzIe323f8izkXx7QrGfUHb2ZzVvI6vs2Tzz4N9_3RPupBLHL_8uXIrG3O7N0_SLU_-Os9fscI28Acqaowa8McsbP84gHifHTUGVuZVMvbgw4Py4NyCG7XdFSZVcUUAJ7lKhZfguDGtSVTDtEfqcJU_Ot-oI6hzthWJ2y9iN-rBSasoMvqNruVAwRuftQEJ-h5PjyArWuMzDNF_hEs7Eq1CzywSiK91sUVTEi6cjrxxQ69SeM5NoVm00
