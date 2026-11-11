# systemconf

Cross-machine configuration (Linux, WSL, Windows) managed with
[chezmoi](https://www.chezmoi.io). The chezmoi source state lives in `home/`
(see `.chezmoiroot`).

No secrets and no personal identifiers are stored here:

- API keys and SSH keys live in **gopass** and are loaded at runtime by the
  fish `keys` command (`keys help`).
- Git name/email are asked once per machine by `chezmoi init` and stored in
  `~/.config/chezmoi/chezmoi.toml` (outside this repo).
- Home paths use `$HOME` / `~`, never a literal user name.

## Contents

| Source (`home/…`) | Target | Notes |
|---|---|---|
| `dot_config/nvim/` | `~/.config/nvim` | Neovim 0.12 config, `lazy-lock.json` tracked |
| `dot_config/fish/` | `~/.config/fish` | config, `keys` command + loader, guarded rustup/uv setup, `fish_plugins` |
| `dot_config/keys/groups.conf` | `~/.config/keys/groups.conf` | which gopass entries become which env vars |
| `dot_config/gopass/create_private_config` | `~/.config/gopass/config` | written only if missing (gopass manages it afterwards) |
| `dot_tmux.conf` | `~/.tmux.conf` | TPM plugins: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`, then `prefix + I` |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | name/email from chezmoi data; `~/.gitconfig.local` for machine extras |
| `dot_bashrc`, `dot_profile` | `~/.bashrc`, `~/.profile` | Ubuntu defaults + nvm/cargo/uv (guarded) |
| `dot_config/{alacritty,kitty,ghostty,rio}/` | terminal configs | |
| `dot_terminfo/a/` | `~/.terminfo/a/` | alacritty terminfo (for distros that lack it) |
| `dot_pi/agent/` | `~/.pi/agent/` | pi `settings.json`, `models.json` (keys via `$ENV`), permission-system config |

Not synced on purpose: `fish_variables`, fisher-installed plugin files
(run `fisher update`), `~/.pi/agent/auth.json`, sessions, caches, the gopass
store itself and its age identity.

## New machine

```sh
# 1. tools: git, fish, tmux, neovim >= 0.12, gopass, node (for pi)
# 2. secrets
gopass clone <your-gopass-remote>       # or: gopass setup --crypto age
keys ssh pull                           # restore ~/.ssh from gopass
# 3. configs
chezmoi init --apply --source ~/systemconf    # or: chezmoi init --apply <git-url>
fish -c 'fisher update'
```

## Day to day

```sh
chezmoi diff            # what would change
chezmoi apply -v        # write configs
chezmoi re-add <file>   # copy an edited target back into this repo
chezmoi cd              # jump here to commit
```
