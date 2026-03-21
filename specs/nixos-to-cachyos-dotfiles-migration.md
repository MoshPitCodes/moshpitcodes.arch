# Plan: NixOS to CachyOS Dotfiles Migration (mise + stow)

## Task Description

Migrate the personal NixOS configuration from [moshpitcodes.nix](https://github.com/MoshPitCodes/moshpitcodes.nix) to the current CachyOS Hyprland install (using Caelestia Shell). The NixOS repo contains ~40 Nix modules that declaratively manage system packages, Hyprland window manager config, shell setup (zsh + oh-my-posh), terminal emulators (Ghostty), development tools, theming (Rose Pine / Colloid GTK), and user services.

The target system is CachyOS Linux (Arch-based, rolling release) running:
- **Hyprland v0.54.2** with **Caelestia Shell v1.5.1** (provides its own bar, launcher, notifications, and config framework)
- **Fish shell** with Starship prompt (replacing the NixOS zsh + oh-my-posh setup)
- **Foot terminal** (replacing Ghostty)
- **pacman/yay/paru** for package management (replacing Nix)

The migration must use **mise-en-place** for development tool version management and **GNU Stow** for dotfile symlink management. No Nix tooling should be carried over.

## Goal

Produce a fully functional, stow-managed dotfiles repository (`moshpitcodes.arch`) that:
1. Captures all user-level configuration from the NixOS repo as plain config files
2. Uses GNU Stow packages to symlink configs into `~/.config/` and other XDG locations
3. Uses mise-en-place to manage development tool versions (replacing `nix develop` shells)
4. Preserves the user preferred software stack, keybindings, theming, and workflow
5. Coexists cleanly with Caelestia Shell managed Hyprland config layer
6. Includes a bootstrap script for fresh installs

## Scope

### In-Scope: User-Level Configs (Home Manager equivalents)
- **Shell**: Fish config, abbreviations, functions, Starship prompt (migrated from zsh/oh-my-posh)
- **Terminal**: Foot config (migrated from Ghostty settings - font, opacity, padding)
- **Hyprland overrides**: ~/.config/caelestia/hypr-user.conf and hypr-vars.conf (keybinds, monitor layout, workspace rules, exec-once)
- **Git**: .gitconfig with identity, signing, aliases, delta diff
- **GPG and SSH**: Agent configs, key references
- **Development tools**: mise config (.mise.toml) for Node, Python, Go, Rust, Terraform, kubectl, helm, etc.
- **Editor**: VSCode/VSCodium settings + extensions list, Neovim config
- **Btop**: Theme and config
- **Bat**: Theme config
- **Lazygit**: Config
- **Yazi**: File manager config
- **Fastfetch**: System info config
- **Cava**: Audio visualizer config
- **Tmux**: Config
- **FZF**: Config and keybindings
- **Wallpapers**: Collection from NixOS repo
- **Theming**: GTK theme, icon theme, cursor theme, font config
- **XDG MIME**: Default application associations
- **Scripts**: Utility scripts from NixOS repo (backup-repos, etc.)
- **OpenCode**: AI development config (already present in workspace)

### In-Scope: Package Management
- **Pacman package list**: Explicit list of packages to install via pacman/paru
- **Flatpak list**: Any apps managed via Flatpak
- **mise tool versions**: Development runtime versions

### In-Scope: Bootstrap
- **Install script**: Automates stow, package installation, and mise setup on a fresh CachyOS install

## Non-Goals
- **System-level NixOS config (modules/core/)**: Bootloader, kernel, hardware config, systemd services, pipewire, network, security, samba, nvidia drivers - these are managed by CachyOS/pacman directly, not by this dotfiles repo
- **NixOS flake infrastructure**: No flake.nix, flake.lock, overlays, or Nix expressions
- **Home Manager**: No Nix-based home directory management
- **Nix dev shells**: Replaced entirely by mise-en-place
- **Multi-host support**: The NixOS repo supports desktop/laptop/vmware-guest; this repo targets the desktop only (for now)
- **Caelestia Shell internals**: We do NOT modify Caelestia own managed configs (~/.config/hypr/hyprland.conf, ~/.config/hypr/hyprland/); we only use its user override files
- **Secrets migration**: Doppler/secrets.nix patterns are out of scope; secrets will be handled separately
- **Waybar**: Caelestia Shell provides its own bar (AGS-based); Waybar config is not migrated
- **Rofi**: Caelestia provides its own launcher; Rofi config is not migrated
- **SwayNC**: Caelestia provides its own notification system; SwayNC config is not migrated
- **Hyprpaper/Waypaper**: Caelestia manages wallpapers; these are not migrated as separate configs
- **Spicetify**: Spotify theming is low priority and deferred
- **Discord theming**: BetterDiscord/Equicord theming is deferred

## Relevant Files

### Source Repository (moshpitcodes.nix)
- `modules/home/` - All user-level Nix modules (~40 files) containing config values to extract
- `modules/home/hyprland/` - Hyprland config (keybinds, monitors, rules, desktop-overrides)
- `modules/home/zsh/` - Shell config (aliases, env vars, plugins)
- `modules/home/waybar/` - Waybar config (NOT migrated - Caelestia replaces this)
- `modules/home/scripts/` - Utility shell scripts
- `modules/home/development/` - Dev tool configs (opencode, sidecar)
- `modules/home/ghostty.nix` - Terminal config (migrate settings to foot)
- `modules/home/git.nix` - Git identity and config
- `modules/home/gpg.nix` - GPG agent config
- `modules/home/openssh.nix` - SSH config
- `modules/home/bat.nix` - Bat config
- `modules/home/btop.nix` - Btop config
- `modules/home/starship.nix + starship.toml` - Prompt config
- `modules/home/theming.nix` - GTK/cursor/icon theme
- `modules/home/packages.nix` - User package list (translate to pacman)
- `modules/home/xdg-mimes.nix` - Default app associations
- `modules/core/fonts.nix` - Font packages (translate to pacman)
- `wallpapers/` - Wallpaper collection

### Target Repository (moshpitcodes.arch)
- `specs/` - This plan and future specs
- `docs/` - Documentation templates
- `.opencode/` - OpenCode workspace config (already set up)

### Target System (Current State)
- `~/.config/hypr/hyprland.conf` - Caelestia-managed, sources user overrides
- `~/.config/caelestia/hypr-user.conf` - EMPTY - user Hyprland overrides go here
- `~/.config/caelestia/hypr-vars.conf` - EMPTY - user variable overrides go here
- `~/.config/hypr/variables.conf` - Caelestia defaults (foot terminal, zen-browser, codium, etc.)
- `~/.config/fish/config.fish` - Current fish config with starship, eza, zoxide, git abbrs
- `~/.config/foot/foot.ini` - Current foot config (JetBrains Mono, alpha 0.78)
- `~/.config/starship.toml` - Current starship prompt config (316 lines)
- `~/.config/btop/` - Current btop config
- `~/.config/fastfetch/` - Current fastfetch config

## Proposed Approach

### Architecture: Stow Package Layout

The repository root will contain one directory per stow package. Each package mirrors the target directory structure relative to `$HOME`. Running `stow --target=$HOME <package>` from the repo root creates symlinks in `$HOME`.

```
moshpitcodes.arch/
|-- bootstrap.sh              # Fresh install script
|-- packages/
|   |-- pacman.txt            # Explicit pacman package list
|   |-- paru-aur.txt          # AUR packages
|   +-- flatpak.txt           # Flatpak apps
|-- mise/                     # Stow package: mise config
|   +-- .mise.toml            # Global mise tool versions
|-- fish/                     # Stow package: fish shell
|   +-- .config/
|       +-- fish/
|           |-- config.fish
|           |-- conf.d/
|           |-- functions/
|           +-- completions/
|-- starship/                 # Stow package: prompt
|   +-- .config/
|       +-- starship.toml
|-- foot/                     # Stow package: terminal
|   +-- .config/
|       +-- foot/
|           +-- foot.ini
|-- hyprland/                 # Stow package: Hyprland user overrides
|   +-- .config/
|       +-- caelestia/
|           |-- hypr-user.conf
|           +-- hypr-vars.conf
|-- git/                      # Stow package: git config
|   |-- .gitconfig
|   +-- .config/
|       +-- git/
|           +-- ignore
|-- gpg/                      # Stow package: GPG
|   +-- .gnupg/
|       +-- gpg-agent.conf
|-- ssh/                      # Stow package: SSH
|   +-- .ssh/
|       +-- config
|-- btop/                     # Stow package: btop
|   +-- .config/
|       +-- btop/
|           +-- btop.conf
|-- bat/                      # Stow package: bat
|   +-- .config/
|       +-- bat/
|           +-- config
|-- lazygit/                  # Stow package: lazygit
|   +-- .config/
|       +-- lazygit/
|           +-- config.yml
|-- yazi/                     # Stow package: yazi
|   +-- .config/
|       +-- yazi/
|-- fastfetch/                # Stow package: fastfetch
|   +-- .config/
|       +-- fastfetch/
|           +-- config.jsonc
|-- cava/                     # Stow package: cava
|   +-- .config/
|       +-- cava/
|           +-- config
|-- tmux/                     # Stow package: tmux
|   +-- .config/
|       +-- tmux/
|           +-- tmux.conf
|-- neovim/                   # Stow package: neovim
|   +-- .config/
|       +-- nvim/
|-- vscode/                   # Stow package: vscode/codium
|   +-- .config/
|       |-- Code - OSS/
|       |   +-- User/
|       |       +-- settings.json
|       +-- VSCodium/
|           +-- User/
|               +-- settings.json
|-- gtk/                      # Stow package: GTK theming
|   +-- .config/
|       |-- gtk-3.0/
|       |   +-- settings.ini
|       +-- gtk-4.0/
|           +-- settings.ini
|-- xdg/                      # Stow package: XDG defaults
|   +-- .config/
|       +-- mimeapps.list
|-- scripts/                  # Stow package: user scripts
|   +-- .local/
|       +-- bin/
|           +-- backup-repos.sh
|-- wallpapers/               # Stow package: wallpapers
|   +-- .local/
|       +-- share/
|           +-- wallpapers/
|-- specs/                    # Plan documents (not stowed)
|-- docs/                     # Documentation (not stowed)
+-- .opencode/                # Workspace tooling (not stowed)
```

### Key Design Decisions

1. **Caelestia coexistence**: Caelestia Shell owns `~/.config/hypr/hyprland.conf` and the `~/.config/hypr/hyprland/` directory. Our customizations go exclusively into `~/.config/caelestia/hypr-user.conf` and `hypr-vars.conf`, which Caelestia sources at the end of its config chain. This means our keybinds, monitor layout, exec-once commands, and variable overrides layer on top without conflicting.

2. **Fish over Zsh**: The current system uses Fish (not Zsh). The NixOS repo zsh aliases and env vars will be translated to Fish abbreviations and functions. Oh-My-Posh is replaced by Starship (already configured with 316-line config).

3. **Foot over Ghostty**: The NixOS Ghostty config (FiraCode, size 12, Everforest theme, 0.95 opacity) will be translated to equivalent Foot settings. The current Foot config already has JetBrains Mono, size 12, alpha 0.78 - the user may want to reconcile these.

4. **mise-en-place for dev tools**: Instead of `nix develop` shells, mise will manage tool versions globally via `~/.mise.toml`. Tools like Node, Python, Go, Rust, Terraform, kubectl, helm, etc. will be declared there.

5. **Package lists as text files**: Rather than Nix expressions, we maintain plain text lists of pacman packages, AUR packages, and Flatpak apps. The bootstrap script reads these.

6. **No Waybar/Rofi/SwayNC**: Caelestia Shell provides AGS-based replacements for all three. These NixOS modules are not migrated.

### Migration Strategy Per NixOS Module

| NixOS Module | Migration Target | Notes |
|---|---|---|
| `hyprland/default.nix` | `hyprland/.config/caelestia/hypr-user.conf` | Extract keybinds, exec-once, window rules |
| `hyprland/desktop-overrides.nix` | `hyprland/.config/caelestia/hypr-vars.conf` | Monitor layout, GPU env vars |
| `zsh/default.nix` | `fish/.config/fish/config.fish` | Translate aliases to abbrs, env vars, plugins |
| `ghostty.nix` | `foot/.config/foot/foot.ini` | Font, opacity, padding translation |
| `git.nix` | `git/.gitconfig` | Identity, signing, aliases, delta |
| `gpg.nix` | `gpg/.gnupg/gpg-agent.conf` | Agent config |
| `openssh.nix` | `ssh/.ssh/config` | Host configs |
| `starship.nix + .toml` | `starship/.config/starship.toml` | Already exists on system - reconcile |
| `bat.nix` | `bat/.config/bat/config` | Theme setting |
| `btop.nix` | `btop/.config/btop/btop.conf` | Already exists on system - capture |
| `lazygit.nix` | `lazygit/.config/lazygit/config.yml` | Config translation |
| `yazi.nix` | `yazi/.config/yazi/` | Config files |
| `fastfetch.nix` | `fastfetch/.config/fastfetch/config.jsonc` | Already exists - capture |
| `tmux.nix` | `tmux/.config/tmux/tmux.conf` | Config translation |
| `fzf.nix` | Fish integration in `fish/` | FZF keybindings via fish plugin |
| `theming.nix` | `gtk/.config/gtk-3.0/settings.ini` etc. | GTK theme, icons, cursor |
| `xdg-mimes.nix` | `xdg/.config/mimeapps.list` | Default app associations |
| `packages.nix` | `packages/pacman.txt` | Translate nix pkgs to pacman names |
| `scripts/` | `scripts/.local/bin/` | Copy and adapt shell scripts |
| `backup-repos.nix` | `scripts/.local/bin/backup-repos.sh` | Systemd user service to script + timer |
| `nvim.nix` | `neovim/.config/nvim/` | Neovim config (may use nvf or standalone) |
| `vscode.nix` | `vscode/.config/Code - OSS/User/settings.json` | Settings + extensions list |
| `waybar/` | **NOT MIGRATED** | Caelestia provides bar |
| `rofi.nix` | **NOT MIGRATED** | Caelestia provides launcher |
| `swaync.nix` | **NOT MIGRATED** | Caelestia provides notifications |
| `hyprpaper.nix` | **NOT MIGRATED** | Caelestia manages wallpapers |
| `hypridle.nix` | **EVALUATE** | May need user override in Caelestia |
| `hyprlock.nix` | **EVALUATE** | May need user override in Caelestia |
| `spicetify.nix` | **DEFERRED** | Low priority |
| `discord/` | **DEFERRED** | Low priority |
| `audacious.nix` | **DEFERRED** | Low priority |
| `gaming.nix` | **DEFERRED** | Steam config via pacman |

## Risks And Assumptions

- **Assumption**: The user wants to keep Fish shell (current) rather than switch back to Zsh (NixOS). If Zsh is preferred, the fish stow package becomes a zsh stow package instead.
- **Assumption**: The user wants to keep Foot terminal (current Caelestia default) rather than install Ghostty. If Ghostty is preferred, we add a ghostty stow package and update hypr-vars.conf.
- **Assumption**: Caelestia Shell hypr-user.conf and hypr-vars.conf are the correct override points and will persist across Caelestia updates.
- **Risk**: Some NixOS modules embed config values in Nix expressions that are hard to extract without cloning the repo and reading each file. The engineer will need to clone moshpitcodes.nix locally to extract exact values.
- **Risk**: Package name mismatches between nixpkgs and Arch/AUR repos. Some packages have different names or may not exist in AUR.
- **Risk**: mise-en-place may not support all tools that were available via nix develop. Fallback is direct pacman/AUR installation.
- **Risk**: Stow conflicts if existing config files (not symlinks) exist in ~/.config/. The bootstrap script must handle backup/removal of existing files before stowing.
- **Risk**: Caelestia Shell updates could change the override mechanism. Pin to known-working version during migration.
- **Assumption**: The current system starship.toml (316 lines) is the desired prompt config and does not need to be replaced by the NixOS repo version.
- **Assumption**: Secrets (API keys, passwords, private keys) are handled out-of-band and not stored in this repo.

## Implementation Phases

### Phase 1: Repository Scaffolding and Tool Setup
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Install `mise` and `stow` via pacman/paru
  - Initialize git repo structure with stow package directories
  - Create `.stow-local-ignore` patterns (exclude specs/, docs/, .opencode/, packages/, .git)
  - Create initial `packages/pacman.txt` with stow and mise as first entries
  - Create `mise/.mise.toml` with initial tool versions
  - Verify `stow --simulate` works from repo root
  - Create `.gitignore` for the repo

### Phase 2: Shell and Terminal Migration
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Capture current `~/.config/fish/` into `fish/` stow package
  - Translate any missing zsh aliases/functions from NixOS repo to fish equivalents
  - Capture current `~/.config/foot/foot.ini` into `foot/` stow package
  - Reconcile Ghostty settings (font, theme, opacity) with current Foot config
  - Capture current `~/.config/starship.toml` into `starship/` stow package
  - Verify: unstow + restow produces identical shell experience

### Phase 3: Hyprland and Desktop Overrides
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Clone `moshpitcodes.nix` temporarily to extract Hyprland keybinds, window rules, exec-once, monitor config
  - Create `hyprland/.config/caelestia/hypr-user.conf` with extracted keybinds and rules
  - Create `hyprland/.config/caelestia/hypr-vars.conf` with variable overrides (terminal, browser, editor, gaps, opacity, etc.)
  - Evaluate hypridle/hyprlock - add overrides if Caelestia does not cover them
  - Verify: `hyprctl reload` applies overrides without errors

### Phase 4: Git, GPG, SSH
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Extract git config from git.nix into `git/.gitconfig`
  - Extract GPG agent config into `gpg/.gnupg/gpg-agent.conf`
  - Extract SSH config into `ssh/.ssh/config` (with proper permissions handling)
  - Verify: `git log --show-signature` works, SSH agent forwards correctly

### Phase 5: Development Tools (mise)
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Audit NixOS packages.nix and development/ modules for dev tool list
  - Configure `mise/.mise.toml` with: node, python, go, rust, terraform, kubectl, helm, k9s, etc.
  - Add mise activation to fish config (`mise activate fish | source`)
  - Verify: `mise install` succeeds, `node --version` / `python --version` etc. return expected versions

### Phase 6: Application Configs
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Capture/create stow packages for: btop, bat, lazygit, yazi, fastfetch, cava, tmux, fzf, neovim
  - Extract NixOS config values where current system configs are missing
  - Create `vscode/` stow package with settings.json and extensions list
  - Verify: each app launches with correct config after stow

### Phase 7: Theming and XDG
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Create `gtk/` stow package with GTK 3/4 settings (theme, icons, cursor, font)
  - Create `xdg/` stow package with mimeapps.list
  - Verify: GTK apps use correct theme, file associations work

### Phase 8: Scripts, Wallpapers and Utilities
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Migrate utility scripts from NixOS repo to `scripts/.local/bin/`
  - Adapt NixOS-specific scripts (nixos-rebuild wrappers become pacman equivalents)
  - Create backup-repos script + optional systemd user timer
  - Copy wallpaper collection to `wallpapers/.local/share/wallpapers/`
  - Verify: scripts are executable and in `$PATH`

### Phase 9: Package Lists and Bootstrap Script
- **Owner**: `senior-engineer`
- **Outcomes**:
  - Complete `packages/pacman.txt` - full list of desired pacman packages
  - Complete `packages/paru-aur.txt` - AUR packages
  - Complete `packages/flatpak.txt` - Flatpak apps (if any)
  - Create `bootstrap.sh` that: installs packages, installs mise, runs stow for all packages, runs mise install
  - Verify: bootstrap script runs idempotently on current system

### Phase 10: Documentation and QA
- **Owner**: `qa-engineer` (validation), `senior-engineer` (docs)
- **Outcomes**:
  - Write README.md with repo structure, usage, and bootstrap instructions
  - Write docs/installation.md for fresh CachyOS install
  - Full validation pass: unstow everything, restow, verify all configs work
  - Test bootstrap script on current system (idempotent run)
  - Document any manual steps that cannot be automated

## Team Orchestration

This is a large migration with many independent config extractions. The work is primarily implementation-heavy with clear extraction patterns.

- Use the existing OpenCode delivery roles deliberately.
- Prefer `product-manager` for planning refinement, `staff-engineer` for technical review, `senior-engineer` for implementation, and `qa-engineer` for validation.
- Use `todowrite` to track execution and `task` to delegate meaningful stages when the plan is executed.

### Team Members
- `team-lead` - coordinates stages, approvals, and handoffs; decides phase ordering and parallelism
- `product-manager` - refines scope, phases, and acceptance criteria; resolves open questions about shell/terminal preferences
- `staff-engineer` - reviews stow package architecture, mise config approach, Caelestia override strategy; flags risks
- `senior-engineer` - implements all phases; extracts configs from NixOS repo; creates stow packages
- `qa-engineer` - validates each phase; runs stow simulate; verifies app configs load correctly

## Step By Step Tasks

### 1. Install Prerequisites (mise + stow)
- **Owner**: `senior-engineer`
- **Depends On**: none
- **Parallel**: true
- **Deliverables**:
  - `paru -S mise stow` executed successfully
  - Both tools available in `$PATH`

### 2. Create Repository Scaffold
- **Owner**: `senior-engineer`
- **Depends On**: Task 1
- **Parallel**: false
- **Deliverables**:
  - All stow package directories created (empty)
  - `.stow-local-ignore` file created
  - `.gitignore` created
  - `stow --simulate --verbose fish` (dry run) works from repo root

### 3. Capture Current Fish Shell Config
- **Owner**: `senior-engineer`
- **Depends On**: Task 2
- **Parallel**: true (with Tasks 4-7)
- **Deliverables**:
  - `fish/.config/fish/config.fish` - current config captured
  - `fish/.config/fish/conf.d/` - any conf.d fragments
  - `fish/.config/fish/functions/` - custom functions
  - `fish/.config/fish/completions/` - custom completions
  - NixOS zsh aliases translated to fish abbreviations where missing

### 4. Capture Current Foot Terminal Config
- **Owner**: `senior-engineer`
- **Depends On**: Task 2
- **Parallel**: true
- **Deliverables**:
  - `foot/.config/foot/foot.ini` - current config captured
  - Reconciliation notes: Ghostty (FiraCode, Everforest, 0.95) vs Foot (JetBrains Mono, 0.78)

### 5. Capture Current Starship Config
- **Owner**: `senior-engineer`
- **Depends On**: Task 2
- **Parallel**: true
- **Deliverables**:
  - `starship/.config/starship.toml` - current 316-line config captured

### 6. Clone NixOS Repo and Extract Hyprland Config
- **Owner**: `senior-engineer`
- **Depends On**: Task 2
- **Parallel**: true
- **Deliverables**:
  - Temporary clone of moshpitcodes.nix
  - Extracted keybinds, window rules, exec-once commands
  - `hyprland/.config/caelestia/hypr-user.conf` created
  - `hyprland/.config/caelestia/hypr-vars.conf` created
  - Temporary clone removed

### 7. Extract Git/GPG/SSH Config from NixOS Repo
- **Owner**: `senior-engineer`
- **Depends On**: Task 6 (needs clone)
- **Parallel**: true (with Task 6 clone)
- **Deliverables**:
  - `git/.gitconfig` with identity, signing, aliases
  - `git/.config/git/ignore` with global gitignore
  - `gpg/.gnupg/gpg-agent.conf`
  - `ssh/.ssh/config` (template - no actual private keys)

### 8. Create mise Configuration
- **Owner**: `senior-engineer`
- **Depends On**: Task 1, Task 6 (needs NixOS package list)
- **Parallel**: true
- **Deliverables**:
  - `mise/.mise.toml` with all dev tool versions
  - mise activation added to fish config
  - `mise install` succeeds

### 9. Extract Application Configs
- **Owner**: `senior-engineer`
- **Depends On**: Task 2, Task 6
- **Parallel**: true
- **Deliverables**:
  - Stow packages for: btop, bat, lazygit, yazi, fastfetch, cava, tmux, neovim, vscode
  - Each package contains correct config files
  - VSCode extensions list exported

### 10. Create Theming and XDG Packages
- **Owner**: `senior-engineer`
- **Depends On**: Task 6
- **Parallel**: true
- **Deliverables**:
  - `gtk/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`
  - `xdg/.config/mimeapps.list`
  - Font configuration if needed

### 11. Migrate Scripts and Wallpapers
- **Owner**: `senior-engineer`
- **Depends On**: Task 6
- **Parallel**: true
- **Deliverables**:
  - `scripts/.local/bin/` with adapted utility scripts
  - `wallpapers/.local/share/wallpapers/` with wallpaper collection
  - Optional systemd user timer for backup-repos

### 12. Build Package Lists
- **Owner**: `senior-engineer`
- **Depends On**: Task 6 (needs NixOS package list for reference)
- **Parallel**: true
- **Deliverables**:
  - `packages/pacman.txt` - complete pacman package list
  - `packages/paru-aur.txt` - AUR packages
  - `packages/flatpak.txt` - Flatpak apps

### 13. Create Bootstrap Script
- **Owner**: `senior-engineer`
- **Depends On**: Tasks 3-12
- **Parallel**: false
- **Deliverables**:
  - `bootstrap.sh` - idempotent install script
  - Handles: package install, stow all, mise install, post-install hooks
  - Handles: backup of existing configs before stowing

### 14. Write Documentation
- **Owner**: `senior-engineer`
- **Depends On**: Tasks 3-13
- **Parallel**: false
- **Deliverables**:
  - `README.md` - repo overview, structure, usage
  - `docs/installation.md` - fresh install guide
  - `docs/stow-usage.md` - how to add/modify stow packages
  - `docs/mise-usage.md` - how to manage dev tools

### 15. Architecture Review
- **Owner**: `staff-engineer`
- **Depends On**: Tasks 2-12 (review after initial implementation)
- **Parallel**: false
- **Deliverables**:
  - Review of stow package structure
  - Review of Caelestia override approach
  - Review of mise config completeness
  - Risk assessment and recommendations

### 16. Full Validation Pass
- **Owner**: `qa-engineer`
- **Depends On**: Task 15 (after arch review approval)
- **Parallel**: false
- **Deliverables**:
  - Unstow all packages, verify no orphaned symlinks
  - Restow all packages, verify all configs load
  - Run `hyprctl reload` - no errors
  - Open each configured application - correct settings
  - Run `mise install` - all tools install
  - Run `bootstrap.sh` - idempotent (no changes on second run)
  - Test report with pass/fail per stow package

## Acceptance Criteria

- [ ] `stow` and `mise` are installed and functional
- [ ] Repository contains 15 or more stow packages covering all in-scope configs
- [ ] `stow --target=$HOME */` from repo root creates all expected symlinks without conflicts
- [ ] `stow --simulate --target=$HOME */` reports no errors
- [ ] Fish shell loads with correct abbreviations, starship prompt, and mise activation
- [ ] Foot terminal uses configured font, opacity, and theme
- [ ] Hyprland loads user overrides from hypr-user.conf - custom keybinds work
- [ ] `git config user.name` and `git config user.signingkey` return correct values
- [ ] `mise list` shows all configured dev tools with correct versions
- [ ] `mise install` is idempotent (no changes on re-run)
- [ ] GTK applications use the configured theme, icons, and cursor
- [ ] Default file associations open correct applications
- [ ] `bootstrap.sh` runs without errors on current system
- [ ] `bootstrap.sh` is idempotent (safe to re-run)
- [ ] No Nix-related files or expressions exist in the repository
- [ ] All scripts in `.local/bin/` are executable and functional
- [ ] README.md documents the full repo structure and usage

## Validation Commands

- `stow --simulate --verbose --target=$HOME */ 2>&1` - Verify all stow packages can be linked without conflicts
- `stow --simulate --verbose --target=$HOME -D */ 2>&1` - Verify all stow packages can be unlinked cleanly
- `readlink ~/.config/fish/config.fish` - Verify fish config is symlinked to repo
- `readlink ~/.config/foot/foot.ini` - Verify foot config is symlinked to repo
- `readlink ~/.config/caelestia/hypr-user.conf` - Verify Hyprland overrides are symlinked
- `readlink ~/.config/starship.toml` - Verify starship config is symlinked
- `readlink ~/.gitconfig` - Verify git config is symlinked
- `hyprctl reload && hyprctl clients` - Verify Hyprland config loads without errors
- `mise doctor` - Verify mise is healthy
- `mise list` - Verify all tools are installed
- `fish -c "echo \/bin/fish"` - Verify fish shell works
- `git config --list | grep user` - Verify git identity
- `bash bootstrap.sh --dry-run` - Verify bootstrap script logic (if dry-run supported)
- `ls -la ~/.local/bin/` - Verify scripts are symlinked and executable

## Notes

- **Clone strategy**: The NixOS repo should be cloned temporarily during Phase 3/6 to extract config values. It should NOT be kept as a submodule or permanent dependency.
- **Incremental stowing**: Each stow package can be developed and tested independently. The engineer should stow each package as it is created rather than waiting for all packages.
- **Existing config backup**: Before first stow, the bootstrap script should mv existing config files to *.bak to prevent conflicts and allow rollback.
- **Caelestia updates**: Monitor Caelestia Shell releases for changes to the user override mechanism. Current approach (hypr-user.conf / hypr-vars.conf) is based on Caelestia v1.5.1.
- **Sensitive config packages**: The ssh/ and gpg/ stow packages should contain config templates only, never actual private keys. Add explicit .gitignore entries.
- **Font installation**: Fonts (Maple Mono, JetBrains Mono Nerd Font, FiraCode Nerd Font) should be in packages/pacman.txt or packages/paru-aur.txt, not managed by stow.
- **Parallel execution**: Tasks 3-12 are largely independent and can be executed in parallel by the senior-engineer to speed up delivery.
- **Shell preference**: Current system uses Fish. If the user wants to switch to Zsh (matching NixOS setup), this plan needs a minor revision to create a zsh/ stow package instead of fish/.
- **Terminal preference**: Current system uses Foot. If the user wants Ghostty, add ghostty to AUR packages and create a ghostty/ stow package.
- **Stow target directory**: Since the repo lives in ~/Documents/Development/moshpitcodes.arch/ (not directly in $HOME), we must use `stow --target=$HOME <package>` for all stow operations. The bootstrap script and documentation must reflect this.
