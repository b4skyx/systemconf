# systemconf

Cross-machine configuration (Linux, WSL, Windows) managed with
[chezmoi](https://www.chezmoi.io). The chezmoi source state lives in `home/`
(see `.chezmoiroot`).

No secrets and no personal identifiers are stored here:

- API keys and SSH keys live in **gopass** (see [Secrets](#secrets-gopass)) and are
  loaded at runtime by the `keys` command in fish and bash (`keys help`).
- Git name/email are asked once per machine by `chezmoi init` and stored in
  `~/.config/chezmoi/chezmoi.toml` (outside this repo).
- Home paths use `$HOME` / `~`, never a literal user name.

## Contents

| Source (`home/…`) | Target | Notes |
|---|---|---|
| `private_dot_config/nvim/` | `~/.config/nvim` | Neovim 0.12 config, `lazy-lock.json` tracked; colorscheme nord on WSL, gruvbox-material elsewhere; Windows clipboard on WSL |
| `private_dot_config/private_fish/` | `~/.config/fish` | config (starship prompt), `keys` command + loader, `fix_patch`, guarded rustup/uv setup, `fish_plugins` |
| `private_dot_config/keys/` | `~/.config/keys/` | `groups.conf` (which gopass entries become which env vars) and `keys.bash` (bash port of `keys`) |
| `private_dot_config/private_gopass/create_private_config.tmpl` | `~/.config/gopass/config` | written only if missing (gopass manages it afterwards); keychain only on Linux desktops |
| `private_dot_config/starship.toml` | `~/.config/starship.toml` | |
| `dot_tmux.conf` | `~/.tmux.conf` | TPM plugins: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`, then `prefix + I` |
| `dot_gitconfig.tmpl` | `~/.gitconfig` | name/email from chezmoi data; Beyond Compare mergetool on WSL; `~/.gitconfig-turing` for `~/turing/` and `~/.gitconfig.local` for machine extras (both per machine) |
| `dot_bashrc.tmpl`, `dot_profile.tmpl` | `~/.bashrc`, `~/.profile` | openSUSE or Ubuntu base + pyenv/npm/nvm/cargo/uv (guarded) + gopass `keys` |
| `private_dot_config/{alacritty,kitty,ghostty,rio}/` | terminal configs | not on WSL (GUI runs on Windows) |
| `dot_wezterm.lua` | `~/.wezterm.lua` | WezTerm (Windows: `%USERPROFILE%\.wezterm.lua`; opens WSL by default) |
| `dot_wslconfig.tmpl` | `%USERPROFILE%\.wslconfig` | **Windows only**; memory/swap asked by `chezmoi init` on Windows |
| `dot_terminfo/a/` | `~/.terminfo/a/` | alacritty terminfo (for distros that lack it) |
| `dot_pi/private_agent/` | `~/.pi/agent/` | pi `settings.json`, `models.json` (keys via `$ENV`), extensions (`interactive-shell.ts`, permission-system config) |

Which files apply where is decided by `home/.chezmoiignore`:

- **Windows** (native chezmoi): no bash/fish/tmux/terminfo/kitty/ghostty; gets `.wezterm.lua`, `.wslconfig`, git, nvim, pi.
- **WSL**: Unix configs only. **Never touches Windows files** (`/mnt/c/...`):
  the WSL home is the chezmoi target, and `.wslconfig` / GUI terminal configs are ignored.
  Windows-side files are applied by running chezmoi natively on Windows (see below).
- **Linux**: everything except `.wslconfig`.

Not synced on purpose: `fish_variables`, fisher-installed plugin files
(run `fisher update`), `~/.pi/agent/auth.json`, sessions, caches, the gopass
store itself and its age identity.

## Secrets: gopass

Secrets live in a [gopass](https://www.gopass.pw) store (age encryption, git
storage) that syncs through a **private** git repo, `git@personal:b4skyx/keystore`.
The remote only ever sees ciphertext. Entry *names* (e.g. `llm/gemini/personal`)
are visible to anyone with repo access.

| Path in the store | Contents | Used by |
|---|---|---|
| `llm/<provider>/<name>` | API keys (first line), optional `field: value` lines | `keys` → env vars (`~/.config/keys/groups.conf`) |
| `tokens/<service>/<name>` | other tokens (e.g. `tokens/oxicord/personal` → `OXICORD_TOKEN`) | `keys` → env vars |
| `ssh/<file>` | SSH key pairs (`~/.ssh/id_*` and `*.pub`); `~/.ssh/config` stays per machine | `keys ssh push` / `keys ssh pull` |

**One age key per machine.** Every entry is encrypted to *all* recipients in
the store's `.age-recipients`, so all machines share the same secrets, but each
machine decrypts with its own private key (`~/.config/gopass/age/identities`,
passphrase-protected). That file **never leaves its machine** and is not in any
repo. A lost machine is revoked by removing its recipient.

On Linux desktops the passphrase is cached in GNOME Keyring
(`age.usekeychain`), so unlocking is automatic after login. Elsewhere run
`keys unlock` once per boot; the agent keeps it unlocked (`age.agent-timeout 0`).

Everyday commands:

```sh
keys                          # what is loaded (values masked)
keys use <group> <provider>   # switch provider, e.g. keys use openai provider2
keys add <group> <provider>   # store a new key        (see: keys help)
keys rotate <group> [prov]    # replace a key, keep its fields
gopass ls / gopass show <e>   # plain gopass works too
gopass sync                   # pull + push (auto-sync is on for every change)
```

### Machines & recovery

Machine enrolment uses plain gopass commands:

```sh
gopass recipients                     # list machines (age public keys) that can decrypt
gopass recipients add age1...         # enrol a machine: re-encrypts all entries + pushes
gopass recipients remove age1...      # revoke a machine: re-encrypts without it + pushes
```

After revoking a lost or compromised machine, also rotate what it could read
(`keys rotate ...`, new SSH keys): old ciphertext in git history is still
decryptable with its key.

**Keep at least two recipients** (two machines, or one machine plus an offline
recovery key). If the only enrolled machine dies, the store is unrecoverable.
Offline recovery key:

```sh
age-keygen                 # copy the AGE-SECRET-KEY-... line into your password manager / USB; do not save it on disk
gopass recipients add age1...   # its public key
```

To use it: `gopass age identities add AGE-SECRET-KEY-...` on any machine.

Change this machine's passphrase (only re-encrypts the local identities file;
the store and other machines are unaffected):

```sh
cd ~/.config/gopass/age && gopass age agent stop && cp -p identities identities.bak
age -d identities > /dev/shm/ids && age -p -o identities.new /dev/shm/ids && shred -u /dev/shm/ids
chmod 600 identities.new && mv identities.new identities
secret-tool store --label="Password for '$HOME/.config/gopass/age/identities' on 'gopass'" \
  service gopass username "$HOME/.config/gopass/age/identities"     # new passphrase (Linux desktop)
gopass ls >/dev/null && gopass show -o llm/gemini/personal >/dev/null && shred -u identities.bak
```

## New machine

```sh
# 1. tools: git, fish, tmux, neovim >= 0.12, gopass, node (for pi)
#    gopass: https://github.com/gopasspw/gopass/releases (Linux tar.gz/.deb, Windows zip/winget)
# 2. git access: this machine needs an SSH key with access to the private repos
#    (add its key to the GitHub account, or reuse one via a USB stick), and a
#    `Host personal` entry in ~/.ssh/config pointing to github.com with that key.
# 3. secrets: clone, create this machine's key, get enrolled from an existing machine
gopass clone --crypto age git@personal:b4skyx/keystore
gopass git config user.name anonymous            # keep store commits anonymous
gopass git config user.email anonymous@example.invalid
gopass age identities keygen            # choose a passphrase; prints nothing secret
gopass age identities                   # shows this machine's age1... public key
#   -> on an EXISTING machine:  gopass recipients add age1...
gopass config age.agent-timeout 0
gopass config age.usekeychain true      # Linux desktop with GNOME Keyring only
gopass sync && keys unlock && keys ssh pull
# 4. configs
chezmoi init --apply --source ~/systemconf    # or: chezmoi init --apply <git-url>
fish -c 'fisher update'
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm   # then prefix + I
nvim --headless "+Lazy! restore" +qa          # plugins at lazy-lock.json (needs tree-sitter CLI)
```

### Windows (native)

WezTerm and `.wslconfig` live in the Windows profile, so they are applied from
Windows itself (PowerShell), never from WSL:

```powershell
winget install twpayne.chezmoi
git clone git@github.com:b4skyx/systemconf.git $HOME\systemconf
chezmoi init --source $HOME\systemconf     # asks git name/email and WSL memory/swap
chezmoi diff
chezmoi apply -v
```

## Day to day

```sh
chezmoi diff            # what would change
chezmoi apply -v        # write configs
chezmoi re-add <file>   # copy an edited target back into this repo
chezmoi cd              # jump here to commit
```
