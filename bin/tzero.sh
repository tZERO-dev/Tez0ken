#!/usr/bin/env sh
#
# To avoid constantly typeing in `./bin/tzero.sh [ARGS...]`
# You can symlink this file to somewhere in your path
#
#   eg.
#       ln -sf "$(pwd)/bin/tzero.sh" ~/bin/tz
#
# Then just, `tz [ARGS...]`
#

#  true - Flextesa is wrapped with a reverse-proxy, baking blocks upon transactions only
# false - No wrapper, blocks are baked at regular intervals
EASY_BAKE=true
#  true - Use TzIndex-Pro, requires commercial license
# false - Use TzIndex opensource
TZ_INDEX_PRO=false


DOCKER_NETWORK="tzero_tezoken"
DOCKER_PROJECT="tzerotech"

BETTER_CALL_DEV_NAME="tzero_better-call-dev"
FLEXTESA_NAME="tzero_flextesa"
TZ_INDEX_NAME="tzero_tzindex"
TZ_STATS_NAME="tzero_tzstats"
if [ "$EASY_BAKE" = true ]; then
	FLEXTESA_IMAGE="$DOCKER_PROJECT/flextesa-easybake:carthage"
else
	FLEXTESA_IMAGE="$DOCKER_PROJECT/flextesa:carthage"
fi
if [ "$TZ_INDEX_PRO" = true ]; then
	TZ_INDEX_IMAGE="tzindex-pro"
else
	TZ_INDEX_IMAGE="$DOCKER_PROJECT/tzindex:6.0.3"
fi


OK="[38;5;49m"
TITLE="[38;5;150m"
RESET="[0m"
ERROR="[38;5;198m"
NORMAL="[38;5;254m"

# ----------------------------------------------------------------------------------------------------------------------

# Get the full path to either `./bin/tzero.sh`, or the resolved symlink.
test -h "$0" && DIR="$(dirname $(dirname "$(readlink "$0")"))" || DIR="$(dirname $( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P ))"
cd "$DIR"

build_node () {
	printf "  $NORMAL┈≼ Building flextesa ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$RESET"
	if [ "$EASY_BAKE" = true ]; then
		docker build -t "$FLEXTESA_IMAGE" -f Dockerfile_flextesa-easybake .
	else
		docker build -t "$FLEXTESA_IMAGE" -f Dockerfile_flextesa .
	fi
}

build_index () {
	printf "  $NORMAL┈≼ Building tzIndex ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$RESET"
	if [ "$TZ_INDEX_PRO" = true ]; then
		# Commercial indexer
		docker build -t "$TZ_INDEX_IMAGE" -f Dockerfile_tzindex-pro .
	else
		# Opensource indexer
		docker build -t "$TZ_INDEX_IMAGE" -f Dockerfile_tzindex .
	fi
}

build_stats () {
	printf "  $NORMAL┈≼ Building tzStats ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈-┈\n$RESET"
	docker build -t "$DOCKER_PROJECT/tzstats" -f Dockerfile_tzstats .
}

build_better_call_dev () {
	printf "  $NORMAL┈≼ Building Better Call Dev ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$RESET"
	docker build -t "$DOCKER_PROJECT/better-call-dev" -f Dockerfile_better-call-dev .
}

flextesa () {
	flags=""
	if [ "$EASY_BAKE" = false ]; then
		flags="		--interactive"
	fi
	DOCKER_ID=$(docker run $flags \
		--detach \
		--rm \
		--name "$FLEXTESA_NAME" \
		--env "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tzero/bin" \
		--env "flextesa_node_cors_origin=*" \
		--network $DOCKER_NETWORK \
		--publish 20000:20000 \
		--volume "$DIR":/tzero \
		--workdir /tzero \
		"$FLEXTESA_IMAGE")
}

tzindex () {
	DOCKER_ID=$(docker run \
		--detach \
		--rm \
		--name "$TZ_INDEX_NAME" \
		--network "$DOCKER_NETWORK" \
		--publish 8000:8000 \
		--publish 8001:27000 \
		"$TZ_INDEX_IMAGE")
}

tzstats () {
	DOCKER_ID=$(docker run \
		--detach \
		--rm \
		--name "$TZ_STATS_NAME" \
		--publish 8080:8080 \
		"$DOCKER_PROJECT/tzstats")
}

better_call_dev () {
	DOCKER_ID=$(docker run \
		--detach \
		--rm \
		--name "$BETTER_CALL_DEV_NAME" \
		--publish 8081:8081 \
		"$DOCKER_PROJECT/better-call-dev")
}

stop_container () {
	running=$(docker inspect -f '{{.State.Running}}' "$1")
	if [ "$?" = false ]; then
		printf "%sContainer %s not found%s\n" "$ERROR" "$1" "$RESET"
	else
		printf "%sStopping container %s...%s\n" "$NORMAL" "$1" "$RESET"
		docker stop "$1" > /dev/null
		if [ "$?" -eq 0 ]; then
			printf "%s  OK%s\n" "$OK" "$RESET"
		else
			printf "%s  Failed, exited with '%s'%s\n" "$ERROR" "$?" "$RESET"
		fi
	fi
}

compile_contract () {
	printf "${TITLE}Compiling: $NORMAL%s$RESET\n" "$1"
	filename=$(basename "$1")
	out=$(docker run --rm --volume "$DIR":/code --workdir /code ligolang/ligo:next "compile-contract" "--syntax" "cameligo" "$1" "$2")
	if [ ! "$?" -eq 0 ]; then
		printf "  $ERROR┈≼ ERROR ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$NORMAL%b$RESET\n" "$out"
		exit 1
	fi

	annotations=""
	if [ "$filename" = "t0ken.mligo" ]; then
		out=$(echo "$out" \
			| sed "s/%grantor/%from/g" \
			| sed "s/%receiver/%to/g" \
			| sed "s/ %yield/%callback/g" \
		)
		annotations=" - renamed fa1.2 annotations"
	elif [ "$filename" = "registry.mligo" ]; then
		out=$(echo "$out" | sed "s/%yield/%callback/g")
		annotations=" - renamed fa1.2 annotations"
	fi

	echo "$out" > "build/${filename%.*}.tz"
	if [ -n "$DEBUG" ]; then
		printf "  $NORMAL┈≼ CONTRACT ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$RESET%b\n" "$out"
	else
		printf "  ${OK}OK$RESET%s\n" "$annotations"
	fi
}

compile_storage () {
	printf "${TITLE}Compiling Storage: $NORMAL%s$RESET\n" "$1"
	filename=$(basename "$1")
	out=$(docker run --rm --volume "$DIR":/code --workdir /code ligolang/ligo:next "compile-storage" "--syntax" "cameligo" "$1" "$2" "$3")
	if [ ! "$?" -eq 0 ]; then
		printf "  $ERROR┈≼ ERROR ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$NORMAL%b$RESET\n" "$out"
		exit 1
	fi
	echo "$out" > "build/${filename%.*}.origination.tz"
	if [ -n "$DEBUG" ]; then
		printf "  $NORMAL┈≼ STORAGE ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$RESET%b\n" "$out"
	else
		printf "  ${OK}OK$RESET\n"
	fi
}

compile () {
	if [ ! -r "$1" ]; then
		printf "Contract '%s' does not exist, or is not readable.\n" "$1"
	else
		compile_contract "$1" "access"
		origination=$(echo "$1" | rev | cut -f 2- -d '.' | rev)".tz"
		origination="./src/origination/${origination#./src/contracts/}"
		if [ -r "$origination" ]; then
			storage=$(cat "$origination")
			compile_storage "$1" "access" "$storage"
		fi
	fi
}

command_build () {
	if [ "$#" -gt 0 ]; then
		for image in "$@"; do
			case "$image" in
				"node")
					build_node
					;;
				"index")
					build_index
					;;
				"stats")
					build_stats
					;;
				"better_call_dev")
					build_better_call_dev
					;;
				*)
					printf "%sInvalid image name '%s', must be one of 'index', 'stats', 'better_call_dev'%s\n" "$ERROR" "$image" "$RESET"
					print_help
					exit 1
					;;
			esac
		done
	else
		build_node
		build_index
		build_stats
		build_better_call_dev
	fi
}

command_compile () {
	if [ "$#" -gt 0 ]; then
		find=true
		files=$@
	else
		files=$(find ./src/contracts -name "*.mligo")
	fi
	mkdir -p build
	for file in $files; do
		if [ "$find" = true ]; then
			f=$(find ./src/contracts -name "$file*.mligo")
			if [ $(echo -n "$f" | grep -c '^') -lt 1 ]; then
				printf "%sContract not found: %s%s\n" "$ERROR" "$file*.mligo"
			else
				for c in $f; do
					compile "$c"
				done
			fi
		else
			compile "$file"
		fi
	done
}


command_up () {
	# Create Docker network
	[ ! "$(docker network ls | grep $DOCKER_NETWORK)" ] && docker network create "$DOCKER_NETWORK" > /dev/null 2>&1

	if [ "$#" -gt 0 ]; then
		for image in "$@"; do
			case "$image" in
				"node")
				flextesa \
					&& printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$FLEXTESA_NAME" "$OK" "$DOCKER_ID" "$RESET" \
					|| printf "%s Failed to start %s%s\n" "$ERROR" "$FLEXTESA_NAME"
					;;
				"index")
				tzindex \
					&& printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$TZ_INDEX_NAME" "$OK" "$DOCKER_ID" "$RESET" \
					|| printf "%s Failed to start %s%s\n" "$ERROR" "$TZ_INDEX_NAME"
					;;
				"stats")
				tzstats \
					&& printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$TZ_STATS_NAME" "$OK" "$DOCKER_ID" "$RESET" \
					|| printf "%s Failed to start %s%s\n" "$ERROR" "$TZ_STATS_NAME"
					;;
				"better_call_dev")
				better_call_dev \
					&& printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$BETTER_CALL_DEV_NAME" "$OK" "$DOCKER_ID" "$RESET" \
					|| printf "%s Failed to start %s%s\n" "$ERROR" "$BETTER_CALL_DEV_NAME"
					;;
				*)
					printf "%sInvalid image name '%s', must be one of 'flextesa', 'index', 'stats', 'better_call_dev'%s\n" "$ERROR" "$image" "$RESET"
					print_help
					exit 1
					;;
			esac
		done
	else
		flextesa		&& printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$FLEXTESA_NAME" "$OK" "$DOCKER_ID" "$RESET" \
						|| printf "%s Failed to start %s%s\n" "$ERROR" "$FLEXTESA_NAME"
		tzindex			&& printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$TZ_INDEX_NAME" "$OK" "$DOCKER_ID" "$RESET" \
						|| printf "%s Failed to start %s%s\n" "$ERROR" "$TZ_INDEX_NAME"
		tzstats			&& printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$TZ_STATS_NAME" "$OK" "$DOCKER_ID" "$RESET" \
						|| printf "%s Failed to start %s%s\n" "$ERROR" "$TZ_STATS_NAME"
		better_call_dev && printf "%sStarting container %s...%s\n  %.12s%s\n" "$NORMAL" "$BETTER_CALL_DEV_NAME" "$OK" "$DOCKER_ID" "$RESET" \
						|| printf "%s Failed to start %s%s\n" "$ERROR" "$BETTER_CALL_DEV_NAME"
	fi
}

command_down () {
	if [ "$#" -gt 0 ]; then
		for image in "$@"; do
			case "$image" in
				"node")
					stop_container "$FLEXTESA_NAME"
					;;
				"index")
					stop_container "$TZ_INDEX_NAME"
					;;
				"stats")
					stop_container "$TZ_STATS_NAME"
					;;
				"better_call_dev")
					stop_container "$BETTER_CALL_DEV_NAME"
					;;
				*)
					printf "%sInvalid image name '%s', must be one of 'node', 'index', 'stats', 'better_call_dev'%s\n" "$ERROR" "$image" "$RESET"
					print_help
					exit 1
					;;
			esac
		done
	else
		stop_container "$BETTER_CALL_DEV_NAME"
		stop_container "$TZ_STATS_NAME"
		stop_container "$TZ_INDEX_NAME"
		stop_container "$FLEXTESA_NAME"
	fi

}

command_ligo () {
	docker run \
		-it \
		--rm \
		--volume "$DIR":/code \
		--workdir /code \
		ligolang/ligo:next "$@"
}

command_shell () {
	docker exec -it --workdir /tzero tzero_flextesa /bin/sh
}

command_test () {
	docker run \
		--rm \
		--volume "$(pwd)":/code \
		--workdir /code \
		--entrypoint /usr/local/bin/pytest \
		--network tzero_tezoken \
		bakingbad/pytezos:2.4 "$@"
}

deploy () {
	name="$2"
	printf "Deploying %s...\n" "$name"
	out=$(docker exec --workdir /tzero tzero_flextesa bin/deploy.sh "$@" 2>&1)
	if [ "$?" -ne 0 ]; then
		printf "  $ERROR┈≼ ERROR ≽┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈\n$NORMAL%s$RESET\n" "$out"
		exit 1
	fi
	address=$(echo "$out" | grep "New contract.*originated" | awk '{print $3}')
	printf "%s: $NORMAL%s$RESET\n\n" "$name" "$address"
	echo "$out" >> init.log
}

command_init () {
	cp /dev/null init.log

	deploy "tzero" "registry" "build/registry.tz" "build/registry.origination.tz" 3.243 false
	registry=$address

	origination=$(sed 's/KT1LSMRcE2sLqg6H1mmFHG7RVwYNEQnkAtc1/'$registry'/g' build/rules.origination.tz)
	deploy "tzero" "rules" "build/rules.tz" "$origination" 1.421 false
	rules=$address

	origination=$(sed 's/KT1LSMRcE2sLqg6H1mmFHG7RVwYNEQnkAtc1/'$registry'/g' build/t0ken.origination.tz)
	origination=$(echo "$origination" | sed -e 's/KT1LZmAAPb1nr5DCYAp7so6bcJm4xW6pb6XZ/'$rules'/g')
	deploy "tzero" "t0ken" "build/t0ken.tz" "$origination" 6.233 false

	deploy "tzero" "get_allowance"   "build/fa12view.tz" "0" 1.421 false
	deploy "tzero" "get_balance"     "build/fa12view.tz" "0" 1.421 false
	deploy "tzero" "get_totalsupply" "build/fa12view.tz" "0" 1.421 false
}

fail_when_docker () {
	if [ -f /.dockerenv ]; then
		printf "This command cannot be run within a container.\n"
		exit 1
	fi
}

print_help () {
	printf 'Usage: %s [command] [args]\n' "$0"
	printf '\n'
	printf '  CONTAINERS:\n'
	printf '    node              Flextesa Sandbox, Carthage node\n'
	printf '                        - URL:    http://localhost:20000\n'
	printf '    index             BlockWatch-cc Index\n'
	printf '                        - URL:    http://localhost:8000\n'
	printf '    stats             BlockWatch-cc Stats/UI\n'
	printf '                        - URL:    http://localhost:8080\n'
	printf '    better_call_dev   Better-Call-Dev\n'
	printf '                        - URL:    http://localhost:8081\n'
	printf '\n'
	printf '  CONTRACTS:\n'
	printf '    registry       Registry contract\n'
	printf '\n'
	printf '  COMMANDS\n'
	printf '    build   [CONTAINER...]         Builds Docker images\n'
	printf '                                   [DEBUG] Set to true for verbose ligolang output\n'
	printf '    compile [CONTRACT...]          Compiles the given contract\n'
	printf '    init                           Deploys and initializes contracts in dev node\n'
	printf '    up      [CONTAINER...]         Runs a Flextesa dev node\n'
	printf '    down    [CONTAINER...]         Runs a Remix instance\n'
	printf '    shell                          Docker shell with current code volume mounted\n'
	printf '    test    [test name]            Runs unit tests\n'
	printf '    help                           Prints this help message\n'
	printf '\n\n'
	printf '  EXAMPLES\n'
	printf '    Build all Docker images (tzstats, tzindex and better-call-dev):\n'
	printf '      %s build\n' "$0"
	printf '\n'
	printf '    Build tzstats, tzindex Docker images:\n'
	printf '      %s build index stats\n' "$0"
	printf '\n'
	printf '    Compile contracts\n'
	printf '      all contracts\n'
	printf '        %s compile\n' "$0"
	printf '\n'
	printf '      contract matching "registry*.mligo"\n'
	printf '        %s compile registry\n' "$0"
	printf '\n'
	printf '      output raw response from ligo\n'
	printf '        DEBUG=true %s compile registry t0ken\n' "$0"
	printf '\n'
	printf '    Stop stats image, rebuild/update it, and re-start it:\n'
	printf '      %s down stats \n' "$0"
	printf '      %s build stats \n' "$0"
	printf '      %s up stats \n' "$0"
	printf '\n'
	printf '    Running tests:\n'
	printf '      %s test \n' "$0"
	printf '      %s test tests/test_registry.py\n' "$0"
	printf '\n'
}

parse_command () {
	command="$1"
	case "$command" in
		"build")
			shift
			command_build "$@"
			;;
		"compile")
			fail_when_docker
			# Versioned images are not currently supplied, currently re-pulling the image after 24 hours
			if [ ! -f ".ligo" ] || [ $(find ".ligo" -mtime +0 -print) 2> /dev/null ]; then
				touch .ligo
				docker pull ligolang/ligo:next
				# Remove 'none' images after pull
				docker rmi $(docker images -f reference="ligolang/ligo" -f dangling=true -q)
			fi
			args="./bin/tzero.sh $@"
			shift
			command_compile $@
			;;
		"init")
			fail_when_docker
			command_init
			;;
		"up")
			fail_when_docker
			shift
			command_up "$@"
			;;
		"down")
			fail_when_docker
			shift
			command_down "$@"
			;;
		"ligo")
			fail_when_docker
			shift
			command_ligo "$@"
			;;
		"shell")
			fail_when_docker
			command_shell
			;;
		"test")
			shift
			command_test "$@"
			;;
		"help")
			print_help
			;;
		*)
			if [ "$#" -gt 0 ]; then
				printf "%sInvalid command '%s'%s\n" "$ERROR" "$@" "$RESET"
			fi
			print_help
			;;
	esac
}

# -----------------------------------------------------------------------------

parse_command "$@"
