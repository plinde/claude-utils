# claude-utils Makefile

REPO_DIR := $(shell pwd)
BIN_DIR := $(HOME)/bin
EXECUTABLES := ccpm claude-sessions claude-resume

.PHONY: all help install install-all uninstall check clean test list $(addprefix install-,$(EXECUTABLES)) $(addprefix uninstall-,$(EXECUTABLES))

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'
	@echo ""
	@echo "  Per-tool targets:"
	@for exe in $(EXECUTABLES); do \
		printf "    install-%-10s uninstall-%s\n" "$$exe" "$$exe"; \
	done

list: ## List available tools
	@echo "Available tools:"
	@for exe in $(EXECUTABLES); do \
		if [ -x "$(REPO_DIR)/$$exe/$$exe" ]; then \
			echo "  $$exe"; \
		else \
			echo "  $$exe (missing)"; \
		fi \
	done

install: install-all ## Install all tools to ~/bin

install-all: | $(BIN_DIR) ## Install all tools to ~/bin
	@for exe in $(EXECUTABLES); do \
		$(MAKE) --no-print-directory install-$$exe; \
	done

# Generate install-<tool> targets
define INSTALL_TOOL
install-$(1): | $(BIN_DIR)
	@if [ ! -x "$(REPO_DIR)/$(1)/$(1)" ]; then \
		echo "Error: $(1) not found at $(REPO_DIR)/$(1)/$(1)"; \
		exit 1; \
	fi
	@if [ -e "$(BIN_DIR)/$(1)" ]; then \
		echo "Skipping $(1) (exists)"; \
	else \
		ln -s "$(REPO_DIR)/$(1)/$(1)" "$(BIN_DIR)/$(1)"; \
		echo "Linked $(1) -> $(BIN_DIR)/$(1)"; \
	fi
endef

$(foreach exe,$(EXECUTABLES),$(eval $(call INSTALL_TOOL,$(exe))))

$(BIN_DIR):
	@if [ -e "$(BIN_DIR)" ] && [ ! -d "$(BIN_DIR)" ]; then \
		echo "Error: $(BIN_DIR) exists but is not a directory"; \
		echo "Manually copy or symlink the tool to somewhere in your PATH"; \
		exit 1; \
	fi
	@mkdir -p $(BIN_DIR)

uninstall: ## Remove all symlinks from ~/bin
	@for exe in $(EXECUTABLES); do \
		$(MAKE) --no-print-directory uninstall-$$exe; \
	done

# Generate uninstall-<tool> targets
define UNINSTALL_TOOL
uninstall-$(1):
	@if [ -L "$(BIN_DIR)/$(1)" ]; then \
		rm "$(BIN_DIR)/$(1)"; \
		echo "Removed $(BIN_DIR)/$(1)"; \
	elif [ -e "$(BIN_DIR)/$(1)" ]; then \
		echo "Skipping $(1) (exists but not a symlink)"; \
	else \
		echo "Skipping $(1) (not installed)"; \
	fi
endef

$(foreach exe,$(EXECUTABLES),$(eval $(call UNINSTALL_TOOL,$(exe))))

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
