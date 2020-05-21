#include "../registry/accounts.mligo"

type validate_response = {
  accounts : account * account;
  addresses : address * address;
  balances : nat * nat;
  values : nat * nat;
  issuance : bool;
  sender : address;
}

type validate_param = {
  addresses : address * address;
  balances : nat * nat;
  values : nat * nat;
  issuance : bool;
  yield : validate_response contract;
}
