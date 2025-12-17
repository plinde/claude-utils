# claude-utils Justfile

repo_dir := justfile_directory()
bin_dir := env_var('HOME') / "bin"
executables := "ccpm claude-sessions claude-resume"

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

# Install ccpm
install-ccpm:
    @if [ -e "{{ bin_dir }}" ] && [ ! -d "{{ bin_dir }}" ]; then \
        echo "Error: {{ bin_dir }} exists but is not a directory"; \
        echo "Manually copy or symlink ccpm/ccpm to somewhere in your PATH"; \
        exit 1; \
    fi
    @mkdir -p {{ bin_dir }}
    @if [ ! -x "{{ repo_dir }}/ccpm/ccpm" ]; then \
        echo "Error: ccpm not found"; exit 1; \
    fi
    @if [ -e "{{ bin_dir }}/ccpm" ]; then \
        echo "Skipping ccpm (exists)"; \
    else \
        ln -s "{{ repo_dir }}/ccpm/ccpm" "{{ bin_dir }}/ccpm"; \
        echo "Linked ccpm -> {{ bin_dir }}/ccpm"; \
    fi

# Install claude-sessions
install-claude-sessions:
    @if [ -e "{{ bin_dir }}" ] && [ ! -d "{{ bin_dir }}" ]; then \
        echo "Error: {{ bin_dir }} exists but is not a directory"; \
        echo "Manually copy or symlink claude-sessions/claude-sessions to somewhere in your PATH"; \
        exit 1; \
    fi
    @mkdir -p {{ bin_dir }}
    @if [ ! -x "{{ repo_dir }}/claude-sessions/claude-sessions" ]; then \
        echo "Error: claude-sessions not found"; exit 1; \
    fi
    @if [ -e "{{ bin_dir }}/claude-sessions" ]; then \
        echo "Skipping claude-sessions (exists)"; \
    else \
        ln -s "{{ repo_dir }}/claude-sessions/claude-sessions" "{{ bin_dir }}/claude-sessions"; \
        echo "Linked claude-sessions -> {{ bin_dir }}/claude-sessions"; \
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

# Uninstall claude-sessions
uninstall-claude-sessions:
    @if [ -L "{{ bin_dir }}/claude-sessions" ]; then \
        rm "{{ bin_dir }}/claude-sessions"; \
        echo "Removed {{ bin_dir }}/claude-sessions"; \
    else \
        echo "Skipping claude-sessions (not installed or not a symlink)"; \
    fi

# Uninstall claude-resume
uninstall-claude-resume:
    @if [ -L "{{ bin_dir }}/claude-resume" ]; then \
        rm "{{ bin_dir }}/claude-resume"; \
        echo "Removed {{ bin_dir }}/claude-resume"; \
    else \
        echo "Skipping claude-resume (not installed or not a symlink)"; \
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

# Alias for uninstall
clean: uninstall

# Alias for check
test: check
