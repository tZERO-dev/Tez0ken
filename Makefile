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
	# -= Compiling contracts =--------------------------------------------------
ifdef LIGO
	@echo "blah"
else
	@mkdir -p build
	@for file in $(CONTRACTS) ; do															\
		echo "$$file" ;																		\
		tz=$$(basename $$file .mligo)".tz" ;												\
		docker run																			\
			-it																				\
			--rm																			\
			--user $$(id -u $$USER):$$(id -g $$USER)										\
			--volume $$(pwd):/t0ken															\
			--workdir /t0ken																\
			$(LIGO_IMAGE) compile-contract --syntax cameligo $$file access > build/$$tz;	\
	done
endif

clean:
	# -= Cleaning ./build =-----------------------------------------------------
	@rm -f ./build/*
