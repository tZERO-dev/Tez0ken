#include "../registry/accounts.mligo"

type validate_param = {
  source : address;
  destination : address;
  value : nat;
}

type validate_response = {
  request : validate_param;
  source : account;
  destination : account;
}

type validate_request = {
  request : validate_param;
  callback : validate_response contract;
}
