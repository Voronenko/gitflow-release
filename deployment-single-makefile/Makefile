# Make gitflow helper https://github.com/Voronenko/gitflow-release
python = python2.7
SHELL=/bin/bash
MAKE_HELPER := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))/make_helper.sh

PROJECT_NAME=project-name
PROJECT_VERSION=$(shell cat $(PWD)/version.txt)

.PHONY: info build package

info:
	@echo $(PROJECT_VERSION)

build:
	@./clean_build.sh

test:
	@echo "Add tests there if you have any"

package:
	@PROJECT_NAME=$(PROJECT_NAME) PROJECT_VERSION=$(PROJECT_VERSION) $(MAKE_HELPER) package

unpackage:
	@$(MAKE_HELPER) unpackage $(PROJECT_NAME)

release-start:
	@$(MAKE_HELPER) gitflow_release_start

release-finish:
	@$(MAKE_HELPER) gitflow_release_finish

hotfix-start:
	@$(MAKE_HELPER) gitflow_hotfix_start $(filter-out $@,$(MAKECMDGOALS))

hotfix-finish:
	@$(MAKE_HELPER) gitflow_hotfix_finish

%:      # a bit hackish way
	@:    # to pass parameters from command line to action
