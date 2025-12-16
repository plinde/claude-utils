# claude-utils Justfile

repo_dir := justfile_directory()
bin_dir := env_var('HOME') / "bin"
executables := "claude-sessions"

# Show available recipes
default:
    @just --list

# Install symlinks to ~/bin
install:
    @mkdir -p {{ bin_dir }}
    @for exe in {{ executables }}; do \
        if [ -e "{{ bin_dir }}/$exe" ]; then \
            echo "Skipping $exe (exists)"; \
        else \
            ln -s "{{ repo_dir }}/$exe/$exe" "{{ bin_dir }}/$exe"; \
            echo "Linked $exe -> {{ bin_dir }}/$exe"; \
        fi \
    done

# Remove symlinks from ~/bin
uninstall:
    @for exe in {{ executables }}; do \
        if [ -L "{{ bin_dir }}/$exe" ]; then \
            rm "{{ bin_dir }}/$exe"; \
            echo "Removed {{ bin_dir }}/$exe"; \
        fi \
    done

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
