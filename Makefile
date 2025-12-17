# claude-utils Makefile

REPO_DIR := $(shell pwd)
BIN_DIR := $(HOME)/bin
EXECUTABLES := ccpm claude-sessions claude-resume

.PHONY: all help install uninstall check clean test

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

install: | $(BIN_DIR) ## Install symlinks to ~/bin
	@for exe in $(EXECUTABLES); do \
		if [ -e "$(BIN_DIR)/$$exe" ]; then \
			echo "Skipping $$exe (exists)"; \
		else \
			ln -s "$(REPO_DIR)/$$exe/$$exe" "$(BIN_DIR)/$$exe"; \
			echo "Linked $$exe -> $(BIN_DIR)/$$exe"; \
		fi \
	done

$(BIN_DIR):
	@mkdir -p $(BIN_DIR)

uninstall: ## Remove symlinks from ~/bin
	@for exe in $(EXECUTABLES); do \
		if [ -L "$(BIN_DIR)/$$exe" ]; then \
			rm "$(BIN_DIR)/$$exe"; \
			echo "Removed $(BIN_DIR)/$$exe"; \
		fi \
	done

check: ## Check status of symlinks
	@echo "Symlinks in $(BIN_DIR):"
	@for exe in $(EXECUTABLES); do \
		if [ -L "$(BIN_DIR)/$$exe" ]; then \
			echo "  $$exe -> $$(readlink $(BIN_DIR)/$$exe)"; \
		elif [ -e "$(BIN_DIR)/$$exe" ]; then \
			echo "  $$exe (exists but not a symlink)"; \
		else \
			echo "  $$exe (not installed)"; \
		fi \
	done

clean: uninstall ## Alias for uninstall

all: install ## Alias for install

test: check ## Alias for check
