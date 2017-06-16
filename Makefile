# SHELL:=/bin/bash

.DEFAULT_GOAL:=help

#always default ENVIRONMENT to 'unknown' if unset
ENVIRONMENT ?= unknown

ROOTDIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

## Print this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		 skip  { next } \
		 /^#/  { doc=doc "\n" substr($$0, 2); next } \
		 /:/   { sub(/:.*/, "", $$0); printf "\033[1m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)

## Cleanup logs/python virtualenv/binaries
# Usage:
#  make clean
clean: clean-virtualenv

#/ clean just the virtualenv
clean-virtualenv:
	cd "$(ROOTDIR)" ; rm -rf .venv/* bin/vendor/bin/*

## Install all dependencies
# Usage:
#  make deps
deps: deps_python

#/ activates virenv and installs deps
deps_python:
	cd "$(ROOTDIR)"
	@if [ ! -d .venv/bin ] ; \
	then \
		virtualenv --python=python2.7 "$(ROOTDIR)/.venv" ;\
	fi
	. .venv/bin/activate ; \
	./.venv/bin/pip2.7 install -r requirements.txt  ; \

# #/ installs ansible galaxy roles
# deps_ansible:
# 	direnv allow
# 	cd "$(ROOTDIR)"
# 	ansible-galaxy install --role-file="$(ROOTDIR)/ansible/galaxy.yml" --roles-path="$(ROOTDIR)/ansible/vendor_roles"


# If the first argument is "run"...
ifeq (run,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

.PHONY: run

## run a command, ( note: only a single command because awssudo broke something)
# Usage:
#  make run "uptime"
run:
	awssudo $(PROJECT_NAME)-$(ENVIRONMENT) \
		ansible \
			-i $(ROOTDIR)/ansible/inventory/$(ENVIRONMENT)/ec2.py \
			tag_Name_$(COMPONENT) \
			-m shell \
			-a "$(RUN_ARGS)"

