# moshpitcodes.arch

Arch/CachyOS dotfiles for a plain Hyprland desktop using GNU Stow for config deployment and `mise` for development tool versions.

## Layout

- `fish/`, `foot/`, `ghostty/`, `starship/`, `hyprland/`, `hyprlock/`, `hypridle/`, `rofi/`, `swaync/`, `swayosd/`, `waybar/`, `waypaper/`, `git/`, `ssh/`, `gpg/`, `bat/`, `btop/`, `lazygit/`, `fastfetch/`, `yazi/`, `tmux/`, `cava/`, `neovim/`, `micro/`, `mpv/`, `zathura/`, `gnome/`, `firefox/`, `vscode/`, `wallpapers/`, `scripts/`, `xdg/`, `mise/` are Stow packages.
- `packages/` contains package manifests for `pacman`, `AUR`, and `flatpak`.
- `specs/`, `docs/`, and `.opencode/` are workspace files and are not stowed.
- `hyprland/.config/hypr/host.conf` selects the active Hyprland overlay (`desktop`, `laptop`, or `vm`).

## Bootstrap

```bash
./bootstrap.sh
```

The bootstrap script:

- installs packages from `packages/`
- prefers `yay` for AUR packages and falls back to `paru` if needed
- installs `mise` plugins declared in `mise/.mise.toml`
- installs VS Code extensions from `packages/vscode-extensions.txt` when `code` is available
- leaves helper commands available for one-time app setup like `apply-gnome-dconf` and `apply-firefox-userjs`
- restows all dotfile packages into `$HOME`, skipping packages whose targets are already owned by another repo or unmanaged files

## Manual Stow

```bash
stow --target="$HOME" fish foot ghostty starship hyprland hyprlock hypridle rofi swaync swayosd waybar waypaper git ssh gpg bat btop lazygit fastfetch yazi tmux cava neovim micro mpv zathura gnome firefox vscode wallpapers scripts xdg mise
```

## Local-Only Files

- Keep machine-specific git identity in `~/.gitconfig.local`; `import-secrets` can generate it from `GIT_USER_NAME` and `GIT_USER_EMAIL`.
- Keep machine-specific backup destination in `BACKUP_REPOS_DEST`.
- Keep private keys out of this repository.
- Import SSH, GPG, and local Git identity with `import-secrets`; configure values in `~/.config/moshpitcodes/secrets.env` using `docs/templates/secrets.env.template` as a starting point.
- Remove installed Caelestia packages separately if you no longer want the shell on the machine.
