#!/usr/bin/env sh
#
# deploy.sh {account} {contract name} {contract source} {origination file|raw} {burn_cap} {dry_run}
#


TEZOS_CLIENT="tezos-client"
TEZOS_PORT="20000"


if [ "$#" -ne 6 ]; then
	printf "Received '$#' args, but expected 6\n"
	printf "%s {account} {contract name} {contract} {origination} {burn_cap} {dry_run}\n\n" "$0"
	printf "Example:\n\n"
	printf "    %s tzero t0ken build/t0ken.tz build/t0ken.origination.tz 6.66 true\n\n" "$0"
	exit 1
fi

ACCOUNT="$1"
CONTRACT_NAME="$2"
CONTRACT="$3"
BURN_CAP="$5"

if [ ! -f "$CONTRACT" ]; then
	printf "Contract '$CONTRACT' not found\n"
	exit 1
fi

INIT=""
if [ -n "$4" ]; then
	if [ -f "$4" ]; then
		INIT=$(cat $4)
	else
		INIT="$4"
	fi
fi

DRY_RUN=""
if [ "$6" = true ]; then
	DRY_RUN="--dry-run"
fi


if [ -n "$INIT" ]; then
	"$TEZOS_CLIENT" --port "$TEZOS_PORT" originate contract "$CONTRACT_NAME" transferring 0 from "$ACCOUNT" running "$CONTRACT" --burn-cap "$BURN_CAP" --init "$INIT" $DRY_RUN --force
else
	"$TEZOS_CLIENT" --port "$TEZOS_PORT" originate contract "$CONTRACT_NAME" transferring 0 from "$ACCOUNT" running "$CONTRACT" --burn-cap "$BURN_CAP" $DRY_RUN --force
fi
