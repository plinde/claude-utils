# claude-utils Makefile

REPO_DIR := $(shell pwd)
BIN_DIR := $(HOME)/bin
EXECUTABLES := ccpm ccss claude-resume

# Map executable names to their source directories (defaults to same name)
ccpm_DIR := ccpm/go/dist
ccpm_SRC := ccpm/go
ccss_DIR := claude-code-session-search

# Aliases: symlinks that point to other executables (alias -> target)
# Full and medium-hand aliases for command names
ALIASES := claude-code-session-search claude-code-ss claude-code-plugin-manager cc-plugin-manager
claude-code-session-search_TARGET := ccss
claude-code-ss_TARGET := ccss
claude-code-plugin-manager_TARGET := ccpm
cc-plugin-manager_TARGET := ccpm

# Helper function to get directory for an executable
# Usage: $(call get_dir,executable_name)
# Returns $(executable_name)_DIR if defined, otherwise executable_name
get_dir = $(if $($(1)_DIR),$($(1)_DIR),$(1))

.PHONY: all help install install-all uninstall check clean test list build-ccpm $(addprefix install-,$(EXECUTABLES)) $(addprefix uninstall-,$(EXECUTABLES)) $(addprefix install-,$(ALIASES)) $(addprefix uninstall-,$(ALIASES))

.DEFAULT_GOAL := help

# Build ccpm Go binary before installing
build-ccpm:
	@$(MAKE) -C $(REPO_DIR)/$(ccpm_SRC) build

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
		dir=$$($(MAKE) --no-print-directory print-dir-$$exe 2>/dev/null || echo "$$exe"); \
		if [ -x "$(REPO_DIR)/$$dir/$$exe" ]; then \
			echo "  $$exe"; \
		else \
			echo "  $$exe (missing)"; \
		fi \
	done

# Print directory for an executable (used internally)
print-dir-ccss:
	@echo "$(call get_dir,ccss)"
print-dir-ccpm:
	@echo "$(call get_dir,ccpm)"
print-dir-claude-resume:
	@echo "$(call get_dir,claude-resume)"

install: install-all ## Install all tools to ~/bin

install-all: | $(BIN_DIR) ## Install all tools to ~/bin
	@for exe in $(EXECUTABLES); do \
		$(MAKE) --no-print-directory install-$$exe; \
	done
	@for alias in $(ALIASES); do \
		$(MAKE) --no-print-directory install-$$alias; \
	done

# Generate install-<tool> targets
define INSTALL_TOOL
install-$(1): | $(BIN_DIR)
	@if [ ! -x "$(REPO_DIR)/$(call get_dir,$(1))/$(1)" ]; then \
		echo "Error: $(1) not found at $(REPO_DIR)/$(call get_dir,$(1))/$(1)"; \
		exit 1; \
	fi
	@if [ -e "$(BIN_DIR)/$(1)" ]; then \
		echo "Skipping $(1) (exists)"; \
	else \
		ln -s "$(REPO_DIR)/$(call get_dir,$(1))/$(1)" "$(BIN_DIR)/$(1)"; \
		echo "Linked $(1) -> $(BIN_DIR)/$(1)"; \
	fi
endef

$(foreach exe,$(EXECUTABLES),$(eval $(call INSTALL_TOOL,$(exe))))

# ccpm requires building Go binary first
install-ccpm: build-ccpm

# Generate install-<alias> targets (symlinks to other executables)
define INSTALL_ALIAS
install-$(1): install-$($(1)_TARGET) | $(BIN_DIR)
	@if [ -e "$(BIN_DIR)/$(1)" ]; then \
		echo "Skipping $(1) (exists)"; \
	else \
		ln -s "$($(1)_TARGET)" "$(BIN_DIR)/$(1)"; \
		echo "Linked $(1) -> $($(1)_TARGET)"; \
	fi
endef

$(foreach alias,$(ALIASES),$(eval $(call INSTALL_ALIAS,$(alias))))

$(BIN_DIR):
	@if [ -e "$(BIN_DIR)" ] && [ ! -d "$(BIN_DIR)" ]; then \
		echo "Error: $(BIN_DIR) exists but is not a directory"; \
		echo "Manually copy or symlink the tool to somewhere in your PATH"; \
		exit 1; \
	fi
	@mkdir -p $(BIN_DIR)

uninstall: ## Remove all symlinks from ~/bin
	@for alias in $(ALIASES); do \
		$(MAKE) --no-print-directory uninstall-$$alias; \
	done
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

# Generate uninstall-<alias> targets
define UNINSTALL_ALIAS
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

$(foreach alias,$(ALIASES),$(eval $(call UNINSTALL_ALIAS,$(alias))))

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
	@echo "Aliases:"
	@for alias in $(ALIASES); do \
		if [ -L "$(BIN_DIR)/$$alias" ]; then \
			echo "  $$alias -> $$(readlink $(BIN_DIR)/$$alias)"; \
		elif [ -e "$(BIN_DIR)/$$alias" ]; then \
			echo "  $$alias (exists but not a symlink)"; \
		else \
			echo "  $$alias (not installed)"; \
		fi \
	done

clean: uninstall ## Alias for uninstall

all: install ## Alias for install

test: check ## Alias for check
