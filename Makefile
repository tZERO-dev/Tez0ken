# tZERO Solidity Makefile
#
#  - Compiles all '*.mligo' files within './src/contracts'
#


LIGO_IMAGE = "ligolang/ligo:next"
LIGO := $(shell command -v ligo 2> /dev/null)

CONTRACTS = $(shell find src/contracts -name "*.mligo")
PWD = $(shell pwd)

.PHONY: contracts

all: contracts

contracts:
ifdef LIGO
	@mkdir -p build
	@for file in $(CONTRACTS) ; do																						\
		tz=$$(basename "$$file" .mligo)".tz" ;																			\
		contract=$$(basename "$$file" .mligo) ; 																		\
		printf "%s" "$$contract" ;																						\
		$(LIGO) compile-contract --syntax cameligo "$$file" access > build/$$tz;										\
		if [ ! "$$?" -eq 0 ]; then																						\
			printf " - FAILED\n" ;																						\
		elif [ "$$contract" = "t0ken" ] ; then 																			\
			out=$$(echo "$$out" | sed "s/%grantor/%from/g" | sed "s/%receiver/%to/g" | sed "s/%yield/%callback/g") ; 	\
			printf " - annotations renamed for FA1.2\n" ;																\
		elif [ "$$contract" = "registry" ] ; then																		\
	 		out=$$(echo "$$out" | sed "s/%yield/%callback/g") ;															\
			printf " - annotations renamed for FA1.2\n" ;																\
		else																											\
			printf "\n" ;																								\
		fi ;																											\
		echo "$$out" > build/$$tz ;																						\
	done
else
	@mkdir -p build
	@for file in $(CONTRACTS) ; do																						\
		tz=$$(basename "$$file" .mligo)".tz" ;																			\
		contract=$$(basename "$$file" .mligo) ; 																		\
		printf "%s" "$$contract" ;																						\
		out=$$(docker run																								\
			-it																											\
			--rm																										\
			--user $$(id -u $$USER):$$(id -g $$USER)																	\
			--volume $$(pwd):/t0ken																						\
			--workdir /t0ken																							\
			$(LIGO_IMAGE) compile-contract --syntax cameligo "$$file" access) ;											\
		if [ ! "$$?" -eq 0 ]; then																						\
			printf " - FAILED\n" ;																						\
		elif [ "$$contract" = "t0ken" ] ; then 																			\
			out=$$(echo "$$out" | sed "s/%grantor/%from/g" | sed "s/%receiver/%to/g" | sed "s/%yield/%callback/g") ; 	\
			printf " - annotations renamed for FA1.2\n" ;																\
		elif [ "$$contract" = "registry" ] ; then																		\
	 		out=$$(echo "$$out" | sed "s/%yield/%callback/g") ;															\
			printf " - annotations renamed for FA1.2\n" ;																\
		else																											\
			printf "\n" ;																								\
		fi ;																											\
		echo "$$out" | tr -d '\r' > build/$$tz ;																		\
	done
endif

clean:
	@rm -f ./build/*
