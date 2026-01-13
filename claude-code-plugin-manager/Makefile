# Delegate to parent Makefile for this tool
PARENT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..

.PHONY: all install uninstall check test clean

all: install

install:
	@$(MAKE) -C $(PARENT_DIR) install-ccpm
	@$(MAKE) -C $(PARENT_DIR) install-cc-plugin-manager
	@$(MAKE) -C $(PARENT_DIR) install-claude-code-plugin-manager

uninstall:
	@$(MAKE) -C $(PARENT_DIR) uninstall-claude-code-plugin-manager
	@$(MAKE) -C $(PARENT_DIR) uninstall-cc-plugin-manager
	@$(MAKE) -C $(PARENT_DIR) uninstall-ccpm

check:
	@$(MAKE) -C $(PARENT_DIR) check

test: check

clean: uninstall
