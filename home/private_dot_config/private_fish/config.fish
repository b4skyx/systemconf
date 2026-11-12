if status is-interactive
    # Commands to run in interactive sessions can go here

    # Prompt (only where starship is installed)
    if type -q starship
        starship init fish | source
    end
end

set -U fish_greeting ""

# tmux: aliases (ta, tl, ts, ...) and the `tmux` wrapper come from the
# budimanjojo/tmux.fish plugin (fish_plugins); always start tmux in UTF-8 mode.
set -g fish_tmux_unicode true

# Add to fish path $HOME/.local/apps/parasoft_cpptest/cpptest
if test -d $HOME/.local/apps/parasoft_cpptest/cpptest
    set -x PATH $HOME/.local/apps/parasoft_cpptest/cpptest/ $PATH
    set -x PATH $HOME/.local/apps/parasoft_cpptest/cpptest/bin $PATH
end

# Set gcc-9 to gcc as alias (only where gcc-9 is installed)
if type -q gcc-9
    alias gcc='gcc-9'
    alias g++='g++-9'
end

# Mount Calypso SFTP server with optimizations
function mount_calypso
    nohup rclone mount calypso: ~/mnt/calypso \
        --vfs-cache-mode full \
        # --vfs-cache-max-size 10G \
        # --vfs-cache-max-age 2h \
        # --dir-cache-time 2h \
        # --attr-timeout 1h \
        --buffer-size 256M \
        --transfers 8 \
        --checkers 16 \
        --allow-non-empty \
        > /tmp/rclone-mount.log 2>&1 &
    disown
end

alias umount_calypso='fusermount -u ~/mnt/calypso'

# Clear Calypso cache
function clean_calypso_cache
    echo "Clearing calypso cache..."
    rm -rf ~/.cache/rclone/vfs/calypso
    echo "Cache cleared. Remount to refresh."
end

set -Ux PYENV_ROOT $HOME/.pyenv
test -d $PYENV_ROOT/bin; and fish_add_path $PYENV_ROOT/bin

# API keys (GEMINI_API_KEY, DATABRICKS_*_API_KEY, OXICORD_TOKEN, ...) are loaded
# from gopass by conf.d/keys.fish -> see `keys help` and ~/.config/keys/groups.conf

# User-local tool bins (fish_add_path skips directories that do not exist)
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.npm-global/bin
fish_add_path $HOME/.opencode/bin
# ante
fish_add_path $HOME/.ante/bin

# Google Cloud SDK (only where it is installed)
test -f $HOME/google-cloud-sdk/path.fish.inc; and source $HOME/google-cloud-sdk/path.fish.inc

# GPG pinentry needs the tty
set -gx GPG_TTY (tty)

# Default editor
set -gx EDITOR nvim
set -gx VISUAL nvim

# Machine-local overrides (untracked by chezmoi, e.g. homebrew shellenv).
# Sourced last so it can override anything above.
test -f $__fish_config_dir/usersettings.fish; and source $__fish_config_dir/usersettings.fish
