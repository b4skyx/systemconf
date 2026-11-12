# Working with chezmoi in this repo

chezmoi does **not** track anything automatically:

- New files are ignored until you `chezmoi add` them (also inside folders that
  are already managed).
- Edits made directly in `~` stay local until you `chezmoi re-add` them; a
  later `chezmoi apply` would overwrite them with the repo version.
- Nothing is committed or pushed unless you do it.

## Quick routine

```sh
chezmoi status                  # anything changed?
chezmoi diff                    # read the changes (what `apply` would do to ~)
chezmoi re-add                  # copy back all changed plain files (templates are skipped)
chezmoi git -- diff             # check: no secrets, nothing unintended
chezmoi git -- add -A
chezmoi git -- commit -m "..."
chezmoi git -- push
```

On another machine: `chezmoi update` (git pull + apply).

## Common tasks

```sh
chezmoi add ~/.config/foo/config.toml    # start tracking a new file
chezmoi add ~/.config/bar                # a folder (files that exist now; add new ones again later)
chezmoi re-add ~/.tmux.conf              # copy an edited plain file back into the repo
chezmoi edit ~/.bashrc                   # edit the source (needed for templates)
chezmoi apply -v ~/.bashrc               # write one target
chezmoi forget ~/.config/foo/config.toml # stop tracking (file stays in ~)
chezmoi cd                               # shell in the repo
chezmoi unmanaged                        # what in ~ is not tracked
```

## Templates: edit in the repo, never `re-add`

`re-add` skips these. Use `chezmoi edit <target>` then `chezmoi apply <target>`.
If you already edited the target in `~`, look at `chezmoi diff <target>` and
copy the change into the `.tmpl` by hand before applying.

| Target | Source (`home/…`) | Templated because |
|---|---|---|
| `~/.bashrc` | `dot_bashrc.tmpl` | openSUSE vs Ubuntu base |
| `~/.profile` | `dot_profile.tmpl` | openSUSE `/etc/profile` handling |
| `~/.gitconfig` | `dot_gitconfig.tmpl` | name/email from chezmoi data, Beyond Compare on WSL |
| `~/.config/gopass/config` | `private_dot_config/private_gopass/create_private_config.tmpl` | written **once** if missing (`create_`); gopass owns it afterwards, local changes never sync |
| `%USERPROFILE%\.wslconfig` | `dot_wslconfig.tmpl` | memory/swap per machine, Windows only |
| `~/.config/chezmoi/chezmoi.toml` | `.chezmoi.toml.tmpl` | per-machine data; regenerate with `chezmoi init` |

## Plain files: safe to `re-add`

| Area | Files |
|---|---|
| tmux | `~/.tmux.conf` |
| fish | `config.fish`, `conf.d/{keys,rustup,uv,esr-autosar}.fish`, `functions/{keys,fix_patch}.fish`, `completions/keys.fish` |
| keys | `~/.config/keys/groups.conf`, `~/.config/keys/keys.bash` |
| nvim | everything under `~/.config/nvim/` (incl. `spell/en.utf-8.add`) |
| starship | `~/.config/starship.toml` |
| pi | `~/.pi/agent/extensions/interactive-shell.ts`, `extensions/pi-permission-system/config.json`, `models.json` |

Keep plain files portable: guard machine-specific bits at runtime
(`type -q`, `test -d`, `has('wsl')`, `command -v`) instead of hard-coding paths
or user names.

## Plain files rewritten by tools: re-add on purpose only

| File | Rewritten by | When to re-add |
|---|---|---|
| `~/.config/nvim/lazy-lock.json` | `:Lazy update` | after an update you want on all machines (else `apply` rolls it back) |
| `~/.config/fish/fish_plugins` | `fisher install/remove` | after adding/removing a plugin |
| `~/.pi/agent/settings.json` | pi (versions, `lastChangelogVersion`, default model) | after changing packages/models on purpose; otherwise expect `chezmoi status` noise |

## Never add

- Secrets: API keys go into gopass (`keys add <group> <provider>` + a line in
  `~/.config/keys/groups.conf`), configs reference them as `$VAR`.
- `~/.ssh/*` (keys sync via `keys ssh push|pull`), `~/.config/gopass/age/`.
- Generated/state files: `fish_variables`, `fish_frozen_*.fish`, fisher plugin
  files, tool completions, nvim `spell/*.spl`, pi `auth.json`, sessions,
  `models-store.json`, logs, `*.bak`.

## Where files apply

Decided by `home/.chezmoiignore`:

- **Linux**: everything except `.wslconfig`.
- **WSL**: Unix configs only; never touches Windows files. GUI terminal configs,
  terminfo, `.wezterm.lua` and `.wslconfig` are ignored.
- **Windows** (native chezmoi): no bash/fish/tmux/terminfo/kitty/ghostty; gets
  `.wezterm.lua`, `.wslconfig`, git, nvim, pi.

Windows-only files (`.wezterm.lua`, `.wslconfig`) are edited in `home/` or
re-added from Windows PowerShell, not from WSL. For something that should apply
only on some machines, add a rule to `home/.chezmoiignore` (see the existing
`isWsl` / `.chezmoi.os` blocks) or keep it in an unsynced local file such as
`~/.gitconfig.local`.
