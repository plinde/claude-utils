# claude-utils Justfile

repo_dir := justfile_directory()
bin_dir := env_var('HOME') / "bin"
executables := "ccpm ccss claude-resume"

# Directory mapping for executables (most use same name as executable)
ccpm_dir := "claude-code-plugin-manager"
ccss_dir := "claude-code-session-search"

# Aliases (symlinks to other executables)
aliases := "claude-code-session-search claude-code-ss claude-code-plugin-manager cc-plugin-manager"

# Show available recipes
default:
    @just --list
    @echo ""
    @echo "Per-tool recipes: install-<tool>, uninstall-<tool>"
    @echo "Tools: {{ executables }}"

# List available tools
list:
    @echo "Available tools:"
    @for exe in {{ executables }}; do \
        if [ -x "{{ repo_dir }}/$exe/$exe" ]; then \
            echo "  $exe"; \
        else \
            echo "  $exe (missing)"; \
        fi \
    done

# Install all tools to ~/bin
install: install-all

# Install all tools to ~/bin
install-all:
    @mkdir -p {{ bin_dir }}
    @for exe in {{ executables }}; do \
        just install-$exe; \
    done
    @for alias in {{ aliases }}; do \
        just install-$alias; \
    done

# Install ccpm (Claude Code Plugin Manager)
install-ccpm:
    @if [ -e "{{ bin_dir }}" ] && [ ! -d "{{ bin_dir }}" ]; then \
        echo "Error: {{ bin_dir }} exists but is not a directory"; \
        echo "Manually copy or symlink {{ ccpm_dir }}/ccpm to somewhere in your PATH"; \
        exit 1; \
    fi
    @mkdir -p {{ bin_dir }}
    @if [ ! -x "{{ repo_dir }}/{{ ccpm_dir }}/ccpm" ]; then \
        echo "Error: ccpm not found"; exit 1; \
    fi
    @if [ -e "{{ bin_dir }}/ccpm" ]; then \
        echo "Skipping ccpm (exists)"; \
    else \
        ln -s "{{ repo_dir }}/{{ ccpm_dir }}/ccpm" "{{ bin_dir }}/ccpm"; \
        echo "Linked ccpm -> {{ bin_dir }}/ccpm"; \
    fi

# Install ccss (Claude Code Session Search)
install-ccss:
    @if [ -e "{{ bin_dir }}" ] && [ ! -d "{{ bin_dir }}" ]; then \
        echo "Error: {{ bin_dir }} exists but is not a directory"; \
        echo "Manually copy or symlink {{ ccss_dir }}/ccss to somewhere in your PATH"; \
        exit 1; \
    fi
    @mkdir -p {{ bin_dir }}
    @if [ ! -x "{{ repo_dir }}/{{ ccss_dir }}/ccss" ]; then \
        echo "Error: ccss not found"; exit 1; \
    fi
    @if [ -e "{{ bin_dir }}/ccss" ]; then \
        echo "Skipping ccss (exists)"; \
    else \
        ln -s "{{ repo_dir }}/{{ ccss_dir }}/ccss" "{{ bin_dir }}/ccss"; \
        echo "Linked ccss -> {{ bin_dir }}/ccss"; \
    fi

# Install claude-resume
install-claude-resume:
    @if [ -e "{{ bin_dir }}" ] && [ ! -d "{{ bin_dir }}" ]; then \
        echo "Error: {{ bin_dir }} exists but is not a directory"; \
        echo "Manually copy or symlink claude-resume/claude-resume to somewhere in your PATH"; \
        exit 1; \
    fi
    @mkdir -p {{ bin_dir }}
    @if [ ! -x "{{ repo_dir }}/claude-resume/claude-resume" ]; then \
        echo "Error: claude-resume not found"; exit 1; \
    fi
    @if [ -e "{{ bin_dir }}/claude-resume" ]; then \
        echo "Skipping claude-resume (exists)"; \
    else \
        ln -s "{{ repo_dir }}/claude-resume/claude-resume" "{{ bin_dir }}/claude-resume"; \
        echo "Linked claude-resume -> {{ bin_dir }}/claude-resume"; \
    fi

# Remove all symlinks from ~/bin
uninstall:
    @for alias in {{ aliases }}; do \
        just uninstall-$alias; \
    done
    @for exe in {{ executables }}; do \
        just uninstall-$exe; \
    done

# Uninstall ccpm
uninstall-ccpm:
    @if [ -L "{{ bin_dir }}/ccpm" ]; then \
        rm "{{ bin_dir }}/ccpm"; \
        echo "Removed {{ bin_dir }}/ccpm"; \
    else \
        echo "Skipping ccpm (not installed or not a symlink)"; \
    fi

# Uninstall ccss
uninstall-ccss:
    @if [ -L "{{ bin_dir }}/ccss" ]; then \
        rm "{{ bin_dir }}/ccss"; \
        echo "Removed {{ bin_dir }}/ccss"; \
    else \
        echo "Skipping ccss (not installed or not a symlink)"; \
    fi

# Uninstall claude-resume
uninstall-claude-resume:
    @if [ -L "{{ bin_dir }}/claude-resume" ]; then \
        rm "{{ bin_dir }}/claude-resume"; \
        echo "Removed {{ bin_dir }}/claude-resume"; \
    else \
        echo "Skipping claude-resume (not installed or not a symlink)"; \
    fi

# Install cc-plugin-manager (alias for ccpm)
install-cc-plugin-manager: install-ccpm
    @if [ -e "{{ bin_dir }}/cc-plugin-manager" ]; then \
        echo "Skipping cc-plugin-manager (exists)"; \
    else \
        ln -s "ccpm" "{{ bin_dir }}/cc-plugin-manager"; \
        echo "Linked cc-plugin-manager -> ccpm"; \
    fi

# Uninstall cc-plugin-manager
uninstall-cc-plugin-manager:
    @if [ -L "{{ bin_dir }}/cc-plugin-manager" ]; then \
        rm "{{ bin_dir }}/cc-plugin-manager"; \
        echo "Removed {{ bin_dir }}/cc-plugin-manager"; \
    else \
        echo "Skipping cc-plugin-manager (not installed or not a symlink)"; \
    fi

# Install claude-code-session-search (long-hand alias for ccss)
install-claude-code-session-search: install-ccss
    @if [ -e "{{ bin_dir }}/claude-code-session-search" ]; then \
        echo "Skipping claude-code-session-search (exists)"; \
    else \
        ln -s "ccss" "{{ bin_dir }}/claude-code-session-search"; \
        echo "Linked claude-code-session-search -> ccss"; \
    fi

# Uninstall claude-code-session-search
uninstall-claude-code-session-search:
    @if [ -L "{{ bin_dir }}/claude-code-session-search" ]; then \
        rm "{{ bin_dir }}/claude-code-session-search"; \
        echo "Removed {{ bin_dir }}/claude-code-session-search"; \
    else \
        echo "Skipping claude-code-session-search (not installed or not a symlink)"; \
    fi

# Install claude-code-ss (medium-hand alias for ccss)
install-claude-code-ss: install-ccss
    @if [ -e "{{ bin_dir }}/claude-code-ss" ]; then \
        echo "Skipping claude-code-ss (exists)"; \
    else \
        ln -s "ccss" "{{ bin_dir }}/claude-code-ss"; \
        echo "Linked claude-code-ss -> ccss"; \
    fi

# Uninstall claude-code-ss
uninstall-claude-code-ss:
    @if [ -L "{{ bin_dir }}/claude-code-ss" ]; then \
        rm "{{ bin_dir }}/claude-code-ss"; \
        echo "Removed {{ bin_dir }}/claude-code-ss"; \
    else \
        echo "Skipping claude-code-ss (not installed or not a symlink)"; \
    fi

# Install claude-code-plugin-manager (long-hand alias for ccpm)
install-claude-code-plugin-manager: install-ccpm
    @if [ -e "{{ bin_dir }}/claude-code-plugin-manager" ]; then \
        echo "Skipping claude-code-plugin-manager (exists)"; \
    else \
        ln -s "ccpm" "{{ bin_dir }}/claude-code-plugin-manager"; \
        echo "Linked claude-code-plugin-manager -> ccpm"; \
    fi

# Uninstall claude-code-plugin-manager
uninstall-claude-code-plugin-manager:
    @if [ -L "{{ bin_dir }}/claude-code-plugin-manager" ]; then \
        rm "{{ bin_dir }}/claude-code-plugin-manager"; \
        echo "Removed {{ bin_dir }}/claude-code-plugin-manager"; \
    else \
        echo "Skipping claude-code-plugin-manager (not installed or not a symlink)"; \
    fi

# Check status of symlinks
check:
    @echo "Symlinks in {{ bin_dir }}:"
    @for exe in {{ executables }}; do \
        if [ -L "{{ bin_dir }}/$exe" ]; then \
            echo "  $exe -> $(readlink {{ bin_dir }}/$exe)"; \
        elif [ -e "{{ bin_dir }}/$exe" ]; then \
            echo "  $exe (exists but not a symlink)"; \
        else \
            echo "  $exe (not installed)"; \
        fi \
    done
    @echo "Aliases:"
    @for alias in {{ aliases }}; do \
        if [ -L "{{ bin_dir }}/$alias" ]; then \
            echo "  $alias -> $(readlink {{ bin_dir }}/$alias)"; \
        elif [ -e "{{ bin_dir }}/$alias" ]; then \
            echo "  $alias (exists but not a symlink)"; \
        else \
            echo "  $alias (not installed)"; \
        fi \
    done

# Alias for uninstall
clean: uninstall

# Alias for check
test: check
