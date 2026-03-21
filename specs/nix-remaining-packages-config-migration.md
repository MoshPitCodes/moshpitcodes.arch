# Plan: Migrate Remaining Non-Conflicting Packages and Configs from NixOS

## Task Description

Complete the migration of packages and configuration from the old NixOS config (moshpitcodes.nix) to the Arch/CachyOS dotfiles repo (moshpitcodes.arch). This plan covers only the items that:

1. Exist in the NixOS config but are not yet present in the Arch repo
2. Do not conflict with Caelestia Shell (which owns Hyprland config, bar, launcher, notifications, wallpaper management, theming, hyprlock, and hypridle)

The original migration spec (specs/nixos-to-cachyos-dotfiles-migration.md) established the architecture. Many core items are already migrated (fish, foot, starship, git, gpg, ssh, bat, btop, lazygit, fastfetch, yazi, tmux, cava, neovim, vscode, hyprland overrides, xdg mimes, mise, packages, bootstrap, wallpapers, scripts). This plan identifies the remaining gaps.

## Goal

After this plan is executed, every non-conflicting package and config value from moshpitcodes.nix will either be:
- Present in the Arch repo (as a pacman/AUR/flatpak package entry, stow config, or script), OR
- Explicitly documented as intentionally excluded with a reason

## Scope

### Packages to Add

These packages exist in the NixOS config (modules/home/packages.nix, modules/home/development/, modules/home/language-servers.nix, modules/home/*.nix, modules/core/*.nix) but are missing from the current Arch packages/ manifests.

#### Missing from pacman.txt (available in official repos)

- zathura + zathura-pdf-mupdf - PDF viewer (from media.nix)
- evince - PDF viewer (from gnome.nix)
- file-roller - Archive manager (from gnome.nix)
- gnome-text-editor - Simple text editor (from gnome.nix)
- sushi - Nautilus quick preview (from gnome.nix)
- webp-pixbuf-loader - WebP image preview in Nautilus (from gnome.nix)
- poppler - PDF thumbnails in Nautilus (from gnome.nix)
- ffmpegthumbnailer - Video thumbnails in Nautilus (from gnome.nix)
- libheif - HEIF/HEIC image support (from gnome.nix)
- htop - Process viewer (from packages.nix)
- xdg-utils - XDG utilities (from packages.nix)
- dconf-editor - dconf GUI editor (from packages.nix)
- man-pages - Linux man pages (from packages.nix)
- openssl - SSL toolkit (from packages.nix)
- psmisc - killall and friends (from packages.nix, nixpkgs name: killall)
- pre-commit - Git pre-commit hooks (from language-servers.nix)
- make - Build tool (from language-servers.nix)
- cmake - Build tool (from language-servers.nix)
- meson - Build tool (from language-servers.nix)
- ninja - Build tool (from language-servers.nix)
- gdb - C/C++ debugger (from language-servers.nix)
- httpie - HTTP client (from packages.nix)
- tealdeer - tldr pages (from packages.nix)
- glow - Markdown renderer (from packages.nix)
- hyperfine - Benchmarking tool (from packages.nix)
- tokei - Code statistics (from packages.nix)
- dust - Disk usage (from packages.nix)
- duf - Disk usage (from packages.nix)
- procs - Process viewer (from packages.nix)
- bottom - System monitor (from packages.nix)
- sd - sed alternative (from packages.nix)
- choose - cut alternative (from packages.nix)
- doggo - DNS client (from packages.nix)
- valgrind - Memory debugger (from packages.nix)
- postgresql - Database (from development.nix)
- ansible - Configuration management (from development.nix)
- maven - Java build tool (from development.nix)
- gradle - Java build tool (from development.nix)
- jdk-openjdk - Java runtime (from development.nix)
- firefox - Browser (from browser.nix)
- virt-manager - VM management GUI (from packages.nix)
- virt-viewer - VM viewer (from packages.nix)
- qemu-full - Full QEMU emulator (from virtualization.nix)
- libvirt - Virtualization API (from virtualization.nix)
- bleachbit - System cleaner (from packages.nix)
- winetricks - Wine helper (from packages.nix)
- wine - Windows compatibility (from packages.nix)
- spice-gtk - SPICE client (from virtualization.nix)
- docker - Container runtime (from virtualization.nix)
- vivid - LS_COLORS generator (from vivid.nix)
- shellcheck - Shell linter (from language-servers.nix)
- shfmt - Shell formatter (from language-servers.nix)
- steam - Gaming platform (from steam.nix)

#### Missing from paru-aur.txt (AUR packages)

- chatterino2-git - Twitch chat client (from packages.nix)
- soundwireserver - Audio streaming (from packages.nix)
- aseprite - Pixel art editor (from packages.nix, desktop-only)
- android-studio - Android IDE (from android.nix)
- scrcpy - Android screen mirror (from android.nix)
- heimdall - Samsung ROM flashing (from android.nix)
- faugus-launcher - Windows game launcher (from gaming.nix)
- ckan - KSP mod manager (from gaming.nix)
- corectrl - GPU/CPU tuning (from nvidia.nix)
- doppler-cli-bin - Secrets management (from development.nix)
- talosctl-bin - Talos Linux CLI (from development.nix)
- cilium-cli-bin - Cilium networking CLI (from development.nix)
- bruno-bin - API testing (from language-servers.nix)
- obsidian-bin - Notes app (from obsidian.nix)
- proton-ge-custom-bin - Proton GE for Steam (from steam.nix)
- azure-cli - Azure CLI (from development.nix)
- teamviewer - Remote desktop (from services.nix)
- rancher-desktop-bin - Kubernetes management (from development.nix)

#### Missing from flatpak.txt

- com.github.tchx84.Flatseal - Flatpak permissions manager (from flatpak.nix)

### Configs to Add or Enhance

These are configuration files/values from the NixOS config that are not yet represented in the Arch repo stow packages:

1. **Zathura config** - PDF viewer with Osaka Jade theme colors (from media.nix)
2. **Micro editor config** - Settings, Everforest colorscheme, keybindings, ASM syntax (from micro.nix)
3. **FZF config** - Everforest theme colors, fd/bat/eza integration, keybindings (from fzf.nix)
4. **Vivid/LS_COLORS** - Everforest-themed LS_COLORS and EZA_COLORS (from vivid.nix)
5. **GNOME/dconf settings** - Nautilus preferences, GNOME Text Editor settings (from gnome.nix)
6. **Git aliases expansion** - Additional git aliases from git.nix not in fish abbrs (onefetch, clone, merge, tag, etc.)
7. **MPV config** - gpu-hq profile, hwdec settings (from media.nix)
8. **Firefox policies** - Privacy/performance settings (from browser.nix)
9. **Backup-repos systemd timer** - User timer for automated backups (from backup-repos.nix, script exists but timer does not)
10. **GNOME Keyring service** - Ensure gnome-keyring is started (from gnome.nix)

### Configs Explicitly Excluded (Caelestia Conflicts)

These are intentionally NOT migrated because Caelestia Shell manages them:

| NixOS Module | Reason for Exclusion |
|---|---|
| hyprland/default.nix (core config) | Caelestia owns ~/.config/hypr/hyprland.conf |
| waybar/ | Caelestia provides AGS-based bar |
| rofi.nix | Caelestia provides its own launcher |
| swaync.nix | Caelestia provides its own notification system |
| swayosd.nix | Caelestia provides its own OSD |
| swaylock.nix | Caelestia manages screen locking |
| hyprlock.nix | Caelestia manages screen locking |
| hypridle.nix | Caelestia manages idle behavior |
| hyprpaper.nix / waypaper.nix | Caelestia manages wallpapers |
| theming.nix (GTK/Qt/cursor) | Caelestia manages system theming |
| display-manager.nix | CachyOS manages display manager |
| bootloader.nix | CachyOS manages bootloader |
| nvidia.nix | CachyOS/pacman manages GPU drivers |
| pipewire.nix | CachyOS manages audio |
| network.nix | CachyOS manages networking |
| security.nix | CachyOS manages security |
| wayland.nix | CachyOS manages Wayland session |
| xserver.nix | CachyOS manages X11 |

### Configs Intentionally Deferred

| NixOS Module | Reason |
|---|---|
| spicetify.nix | Low priority, requires Spotify + spicetify-cli setup |
| discord/ | Low priority, BetterDiscord/Equicord theming |
| rider.nix | JetBrains Rider + .NET - install on demand |
| sidecar.nix | Nix-specific overlay tool, not available on Arch |
| zsh/default.nix | Replaced by Fish shell - already migrated |
| ghostty.nix | Replaced by Foot terminal - already migrated |
| audacious.nix | Low priority, install on demand |

### NixOS-Only Items (Not Applicable to Arch)

| Item | Reason |
|---|---|
| nix-tree, nix-diff, comma, nix-prefetch-github, nix-output-monitor, nvd | Nix-specific tools |
| nixd, nil, nixfmt, statix, deadnix | Nix language servers/linters |
| treefmt (Nix config) | Nix-specific formatter config |
| nas-mount.nix / samba.nix | System-level NAS mounts - configure via fstab directly |

## Non-Goals

- Modifying any Caelestia Shell managed config
- Migrating NixOS system-level modules (bootloader, kernel, drivers, etc.)
- Migrating Nix-specific tooling (nix-tree, nil, nixfmt, etc.)
- Setting up secrets management (Doppler, API keys)
- Multi-host support (desktop-only for now)
- Migrating Zsh config (Fish is the target shell)
- Migrating Ghostty config (Foot is the target terminal)

## Relevant Files

### Source (moshpitcodes.nix)
- modules/home/packages.nix - Main user package list (163 lines)
- modules/home/development/development.nix - Dev toolchains (69 lines)
- modules/home/language-servers.nix - LSP servers and dev tools (128 lines)
- modules/home/media.nix - MPV and Zathura config (36 lines)
- modules/home/gnome.nix - GNOME utilities and dconf (53 lines)
- modules/home/micro.nix - Micro editor config (89 lines)
- modules/home/fzf.nix - FZF config with Everforest theme (29 lines)
- modules/home/vivid.nix - LS_COLORS and EZA_COLORS (69 lines)
- modules/home/git.nix - Git config with extended aliases (116 lines)
- modules/home/browser.nix - Firefox policies (87 lines)
- modules/home/gaming.nix - CLI games and utilities (13 lines)
- modules/home/development/android.nix - Android tools (18 lines)
- modules/home/backup-repos.nix - Backup service and timer (92 lines)
- modules/home/obsidian.nix - Obsidian notes (5 lines)
- modules/core/virtualization.nix - Docker, libvirt, SPICE (42 lines)
- modules/core/steam.nix - Steam + Gamescope (127 lines)
- modules/core/flatpak.nix - Flatpak with Flatseal (22 lines)
- modules/core/services.nix - System services (27 lines)
- modules/core/fonts.nix - System fonts (28 lines)

### Target (moshpitcodes.arch)
- packages/pacman.txt - Pacman package manifest (89 lines, needs additions)
- packages/paru-aur.txt - AUR package manifest (8 lines, needs additions)
- packages/flatpak.txt - Flatpak manifest (1 line, needs additions)
- packages/vscode-extensions.txt - VS Code extensions (31 lines, already complete)
- fish/.config/fish/config.fish - Fish config (75 lines, needs FZF/vivid additions)
- scripts/.local/bin/ - User scripts (4 scripts, needs backup timer)
- bootstrap.sh - Bootstrap script (108 lines, may need updates)

## Proposed Approach

### Strategy: Incremental Package and Config Addition

This migration is primarily additive - we are adding missing packages to manifests and creating new stow config packages. The approach is:

1. Audit and categorize every package/config in the NixOS repo against what exists in the Arch repo
2. Add missing packages to the appropriate manifest file (pacman.txt, paru-aur.txt, flatpak.txt)
3. Create new stow packages for configs that do not exist yet (micro, zathura, mpv)
4. Enhance existing stow packages where configs need additional values (fish, git, scripts)
5. Validate that all additions install correctly and do not conflict with Caelestia

### Package Name Translation

Key nixpkgs to Arch package name differences:
- killall -> psmisc
- networkmanagerapplet -> network-manager-applet (already in pacman.txt)
- noto-fonts-color-emoji -> noto-fonts-emoji (already in pacman.txt)
- openjdk25 -> jdk-openjdk
- gradle_9 -> gradle
- wineWow64Packages.wayland -> wine (or wine-staging)
- proton-ge-bin -> proton-ge-custom-bin (AUR)
- libvirtd -> libvirt + qemu-full
- corectrl -> corectrl (AUR)
- android-studio -> android-studio (AUR)

### Config File Creation

New stow packages to create:
- micro/.config/micro/ - settings.json, bindings.json, colorschemes/everforest.micro, syntax/asm.yaml
- mpv/.config/mpv/mpv.conf - gpu-hq profile, hwdec settings
- zathura/.config/zathura/zathurarc - Osaka Jade theme colors

Config enhancements to existing stow packages:
- fish/.config/fish/config.fish - Add FZF Everforest theme vars, LS_COLORS/EZA_COLORS, additional git aliases as abbrs
- fish/.config/fish/conf.d/fzf.fish - FZF configuration (fd integration, preview commands)
- scripts/.config/systemd/user/ - Add backup-repos.service and backup-repos.timer
- git/.gitconfig - Verify all aliases from git.nix are present

## Risks And Assumptions

- **Assumption**: Caelestia Shell v1.5.1 does not manage any of the configs listed in scope. If Caelestia adds management of additional tools (e.g., micro, mpv, zathura), those should be excluded.
- **Assumption**: The user wants all the development tools from the NixOS config. Some (like Android Studio, Rider, Aseprite) may be install-on-demand rather than always-present.
- **Risk**: Some AUR packages may have different names or be unavailable. The engineer should verify each AUR package exists before adding to paru-aur.txt.
- **Risk**: Adding many packages to pacman.txt increases bootstrap time. Consider grouping into required vs optional sections with comments.
- **Risk**: The vivid LS_COLORS generation was done at Nix build time. On Arch, we need to either install vivid and generate at shell startup, or hardcode the generated value.
- **Risk**: Firefox policies on Arch work differently than NixOS - they require a policies.json in the Firefox install directory, not a home-manager module.
- **Assumption**: mise handles Go, Rust, Node, Python, Terraform, kubectl, helm versions. System build tools (gcc, make, cmake) go in pacman.txt.
- **Risk**: Some LSP servers from language-servers.nix may be better managed per-project via mise or editor extensions rather than globally via pacman.

## Implementation Phases

### Phase 1: Package Manifest Audit and Update
- **Owner**: senior-engineer
- **Outcomes**:
  - packages/pacman.txt updated with all missing packages (organized by category with comments)
  - packages/paru-aur.txt updated with all missing AUR packages
  - packages/flatpak.txt updated with Flatseal
  - Each package verified to exist in the Arch repos / AUR

### Phase 2: New Stow Config Packages
- **Owner**: senior-engineer
- **Outcomes**:
  - micro/ stow package created with settings, Everforest colorscheme, keybindings, ASM syntax
  - mpv/ stow package created with gpu-hq profile and hwdec config
  - zathura/ stow package created with Osaka Jade theme
  - Each package stows cleanly with stow --simulate

### Phase 3: Enhance Existing Configs
- **Owner**: senior-engineer
- **Outcomes**:
  - Fish config enhanced with FZF Everforest theme, LS_COLORS/EZA_COLORS, additional git abbrs
  - FZF config added as fish conf.d fragment or environment variables
  - Git config verified to include all aliases from NixOS git.nix
  - Backup-repos systemd user timer created in scripts stow package
  - GNOME Keyring autostart verified (may already be handled by CachyOS)

### Phase 4: Bootstrap Script Update
- **Owner**: senior-engineer
- **Outcomes**:
  - bootstrap.sh updated to stow any new packages (micro, mpv, zathura)
  - Stow package list in bootstrap.sh matches all stow directories
  - Bootstrap runs idempotently

### Phase 5: Validation
- **Owner**: qa-engineer
- **Outcomes**:
  - All new packages install via pacman -S --needed and paru -S --needed
  - All new stow packages link without conflicts
  - Micro editor launches with Everforest theme
  - MPV plays video with gpu-hq profile
  - Zathura opens PDFs with correct theme
  - FZF shows Everforest colors in fish shell
  - LS_COLORS/EZA_COLORS display correctly
  - Backup-repos timer is installable
  - Bootstrap script runs cleanly

## Team Orchestration

- Use the existing OpenCode delivery roles deliberately.
- Prefer product-manager for planning refinement, staff-engineer for technical review, senior-engineer for implementation, and qa-engineer for validation.
- Use todowrite to track execution and task to delegate meaningful stages when the plan is executed.

### Team Members
- team-lead - coordinates stages, approvals, and handoffs
- product-manager - refines scope, phases, and acceptance criteria
- staff-engineer - reviews package selections, config approach, and potential Caelestia conflicts
- senior-engineer - implements all phases: updates manifests, creates stow packages, enhances configs
- qa-engineer - validates package installation, stow linking, and application behavior

## Step By Step Tasks

### 1. Audit Package Manifests Against NixOS Config
- **Owner**: senior-engineer
- **Depends On**: none
- **Parallel**: false
- **Deliverables**:
  - Checklist of every package in NixOS config mapped to Arch package name
  - Each package marked as: already present, to add, excluded (Caelestia), excluded (Nix-only), deferred
  - AUR package existence verified via paru -Ss

### 2. Update packages/pacman.txt
- **Owner**: senior-engineer
- **Depends On**: Task 1
- **Parallel**: true (with Tasks 3, 4)
- **Deliverables**:
  - All missing packages added with category comments
  - New sections: Nautilus support, Build tools, Modern CLI replacements, Virtualization, Gaming
  - Packages verified installable: pacman -Si for each

### 3. Update packages/paru-aur.txt
- **Owner**: senior-engineer
- **Depends On**: Task 1
- **Parallel**: true (with Tasks 2, 4)
- **Deliverables**:
  - All missing AUR packages added
  - Each package verified: paru -Ss

### 4. Update packages/flatpak.txt
- **Owner**: senior-engineer
- **Depends On**: Task 1
- **Parallel**: true (with Tasks 2, 3)
- **Deliverables**:
  - com.github.tchx84.Flatseal added

### 5. Create micro/ Stow Package
- **Owner**: senior-engineer
- **Depends On**: Task 2
- **Parallel**: true (with Tasks 6, 7)
- **Deliverables**:
  - micro/.config/micro/settings.json - Everforest colorscheme, autoindent, tabsize 4, ruler
  - micro/.config/micro/bindings.json - Ctrl+Up/Down scroll, Ctrl+Backspace/Delete word
  - micro/.config/micro/colorschemes/everforest.micro - Full Everforest color definitions
  - micro/.config/micro/syntax/asm.yaml - Assembly comment syntax
  - stow --simulate --target=HOME micro succeeds

### 6. Create mpv/ Stow Package
- **Owner**: senior-engineer
- **Depends On**: none (mpv already in pacman.txt)
- **Parallel**: true (with Tasks 5, 7)
- **Deliverables**:
  - mpv/.config/mpv/mpv.conf with profile=gpu-hq, vo=gpu, hwdec=auto-safe
  - stow --simulate --target=HOME mpv succeeds

### 7. Create zathura/ Stow Package
- **Owner**: senior-engineer
- **Depends On**: Task 2
- **Parallel**: true (with Tasks 5, 6)
- **Deliverables**:
  - zathura/.config/zathura/zathurarc with Osaka Jade theme colors from media.nix
  - stow --simulate --target=HOME zathura succeeds

### 8. Enhance Fish Config with FZF and Vivid Colors
- **Owner**: senior-engineer
- **Depends On**: none
- **Parallel**: true (with Tasks 5-7)
- **Deliverables**:
  - FZF Everforest theme added via FZF_DEFAULT_OPTS environment variable
  - FZF default command set to fd --hidden --strip-cwd-prefix --exclude .git
  - FZF file widget preview using bat/eza
  - FZF directory widget using fd + eza tree preview
  - LS_COLORS set via vivid generate one-dark in config.fish
  - EZA_COLORS set with Everforest palette from vivid.nix
  - Additional git abbreviations added (gf, gaa, gm, gplo, gpso, gpst, gcl, gcm, gcma, gtag, gchb, glog, glol, glola, glols)

### 9. Enhance Git Config with Missing Aliases
- **Owner**: senior-engineer
- **Depends On**: none
- **Parallel**: true
- **Deliverables**:
  - Verify git/.gitconfig includes all aliases from NixOS git.nix: st, co, br, ci, lg
  - Verify delta integration is configured
  - Verify merge.conflictstyle = diff3 and diff.colorMoved = default are set

### 10. Create Backup-Repos Systemd User Timer
- **Owner**: senior-engineer
- **Depends On**: none
- **Parallel**: true
- **Deliverables**:
  - scripts/.config/systemd/user/backup-repos.service - oneshot service calling ~/.local/bin/backup-repos
  - scripts/.config/systemd/user/backup-repos.timer - daily timer with persistent + randomized delay
  - Timer installable via systemctl --user enable --now backup-repos.timer

### 11. Update Bootstrap Script
- **Owner**: senior-engineer
- **Depends On**: Tasks 5-7
- **Parallel**: false
- **Deliverables**:
  - stow_packages array in bootstrap.sh updated to include micro, mpv, zathura
  - stow command in README.md updated to include new packages
  - Bootstrap runs idempotently

### 12. Architecture Review
- **Owner**: staff-engineer
- **Depends On**: Tasks 2-11
- **Parallel**: false
- **Deliverables**:
  - Review of package selections for completeness and correctness
  - Review of new stow packages for proper directory structure
  - Confirm no Caelestia conflicts in new additions
  - Review FZF/vivid integration approach in fish
  - Flag any packages that should be mise-managed vs pacman-managed

### 13. Full Validation Pass
- **Owner**: qa-engineer
- **Depends On**: Task 12
- **Parallel**: false
- **Deliverables**:
  - All pacman packages install without errors
  - All AUR packages install without errors
  - stow --simulate for micro mpv zathura - no conflicts
  - micro launches with Everforest theme visible
  - mpv launches and plays video
  - zathura launches with theme colors visible on PDF
  - Fish shell shows FZF Everforest colors on Ctrl+T
  - eza shows colored output matching Everforest palette
  - backup-repos.timer is valid
  - bootstrap.sh runs without errors (idempotent)
  - Test report with pass/fail per deliverable

## Acceptance Criteria

- [ ] packages/pacman.txt contains all non-conflicting packages from NixOS config (estimated 40+ additions)
- [ ] packages/paru-aur.txt contains all non-conflicting AUR packages (estimated 15+ additions)
- [ ] packages/flatpak.txt contains Flatseal
- [ ] micro/ stow package exists with Everforest theme, keybindings, and settings
- [ ] mpv/ stow package exists with gpu-hq profile
- [ ] zathura/ stow package exists with Osaka Jade theme
- [ ] Fish config includes FZF Everforest theme and fd/bat/eza integration
- [ ] Fish config includes LS_COLORS and EZA_COLORS from vivid.nix Everforest palette
- [ ] All git aliases from NixOS git.nix are present (in .gitconfig or fish abbrs)
- [ ] Backup-repos systemd user timer exists and is valid
- [ ] bootstrap.sh stow_packages array includes all stow directories
- [ ] stow --simulate for all stow packages reports no errors
- [ ] No Caelestia Shell configs are modified or conflicted
- [ ] Every NixOS module is accounted for: migrated, excluded with reason, or deferred with reason

## Validation Commands

- stow --simulate --verbose --target=HOME micro mpv zathura - Verify new stow packages link cleanly
- micro --version - Verify micro is installed
- mpv --version - Verify mpv is installed
- zathura --version - Verify zathura is installed
- fish -c echo FZF_DEFAULT_OPTS - Verify FZF Everforest theme is set
- fish -c echo EZA_COLORS - Verify EZA colors are set
- systemd-analyze verify ~/.config/systemd/user/backup-repos.timer - Verify timer unit is valid
- bash bootstrap.sh - Verify bootstrap runs idempotently
- readlink ~/.config/micro/settings.json - Verify micro config is symlinked
- readlink ~/.config/mpv/mpv.conf - Verify mpv config is symlinked
- readlink ~/.config/zathura/zathurarc - Verify zathura config is symlinked

## Notes

- **Package grouping**: The updated pacman.txt should use comment headers to organize packages by category for readability. Suggested sections: Core CLI, Shell and CLI, Modern CLI Replacements, Build Tools, Development, Cloud and Infrastructure, Kubernetes, Wayland/Hyprland Helpers, Desktop Apps, Media, Gaming, Virtualization, Nautilus Support, Fonts.
- **LSP servers**: Most LSP servers from language-servers.nix are better managed by the editor (Neovim Mason, VSCode extensions) or per-project tooling rather than global pacman packages. Only install globally the ones that are truly system-wide (like shellcheck, shfmt). The engineer should make a judgment call per LSP.
- **Vivid approach**: Two options for LS_COLORS: (a) install vivid and run set -gx LS_COLORS (vivid generate one-dark) in config.fish, or (b) hardcode the generated output. Option (a) is cleaner but adds a startup dependency. Option (b) is faster but harder to maintain. Recommend option (a).
- **Firefox policies**: On Arch, Firefox policies require /etc/firefox/policies/policies.json (system-wide). This is NOT a stow-able home directory config. Recommend deferring Firefox policies since Zen Browser is the primary browser.
- **mise vs pacman for dev tools**: Tools like Go, Rust, Node, Python are already in mise/.mise.toml. Do not duplicate them in pacman.txt. Only add to pacman.txt the tools that mise does not manage (gcc, cmake, make, docker, etc.). Current mise manages: node, python, go, rust, bun, terraform, kubectl, helm.
- **Gaming packages**: Steam is a large dependency tree. Consider adding a comment in pacman.txt marking gaming packages as optional.
- **Virtualization packages**: libvirt/qemu/virt-manager require system-level setup (libvirtd service, user groups). Add a note in the bootstrap script or README about sudo systemctl enable --now libvirtd and sudo usermod -aG libvirt,kvm USER.
- **Android tools**: Android Studio is very large (~1GB). Consider marking as install-on-demand rather than always-present in the manifest.
- **Stow package naming**: New packages (micro, mpv, zathura) follow the existing convention of lowercase tool name as directory name.
- **GNOME Keyring**: CachyOS with Caelestia Shell likely already starts gnome-keyring. Verify before adding any autostart config.
- **dconf settings**: GNOME Text Editor and Nautilus dconf settings from gnome.nix can be applied via dconf load or gsettings set commands in the bootstrap script rather than as stow-managed files.
