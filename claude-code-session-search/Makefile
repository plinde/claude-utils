# Delegate to parent Makefile for this tool
PARENT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..

.PHONY: all install uninstall check test clean

all: install

install:
	@$(MAKE) -C $(PARENT_DIR) install-ccss
	@$(MAKE) -C $(PARENT_DIR) install-claude-code-ss
	@$(MAKE) -C $(PARENT_DIR) install-claude-code-session-search

uninstall:
	@$(MAKE) -C $(PARENT_DIR) uninstall-claude-code-session-search
	@$(MAKE) -C $(PARENT_DIR) uninstall-claude-code-ss
	@$(MAKE) -C $(PARENT_DIR) uninstall-ccss

check:
	@$(MAKE) -C $(PARENT_DIR) check

test:
	./tests/test-ccss.sh

clean: uninstall
