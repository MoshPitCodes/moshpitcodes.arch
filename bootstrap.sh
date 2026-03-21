#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

stow_packages=(
	fish
	foot
	ghostty
	starship
	hyprland
	hyprlock
	hypridle
	rofi
	swaync
	waybar
	waypaper
	git
	ssh
	gpg
	bat
	btop
	lazygit
	fastfetch
	yazi
	tmux
	cava
	neovim
	micro
	mpv
	zathura
	gnome
	firefox
	vscode
	wallpapers
	scripts
	xdg
	mise
)

install_vscode_extensions() {
	local installer
	if command -v code >/dev/null 2>&1; then
		installer="code"
	elif command -v codium >/dev/null 2>&1; then
		installer="codium"
	else
		return
	fi

	while IFS= read -r extension; do
		"$installer" --install-extension "$extension" --force >/dev/null 2>&1 || true
	done < <(read_manifest "$repo_root/packages/vscode-extensions.txt")
}

read_manifest() {
	local file="$1"
	python - "$file" <<'PY'
from pathlib import Path
import sys

items = []
for raw in Path(sys.argv[1]).read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith('#'):
        continue
    items.append(line)

print("\n".join(items))
PY
}

install_pacman() {
	mapfile -t packages < <(read_manifest "$repo_root/packages/pacman.txt")
	if ((${#packages[@]})); then
		sudo pacman -S --needed --noconfirm "${packages[@]}"
	fi
}

upgrade_system() {
	sudo pacman -Syu --noconfirm
}

install_aur() {
	local aur_helper

	if command -v yay >/dev/null 2>&1; then
		aur_helper="yay"
	elif command -v paru >/dev/null 2>&1; then
		aur_helper="paru"
	else
		return
	fi

	mapfile -t packages < <(read_manifest "$repo_root/packages/paru-aur.txt")
	if ((${#packages[@]})); then
		"$aur_helper" -Syu \
			--needed \
			--noconfirm \
			--ask=4 \
			--removemake \
			"${packages[@]}"
	fi
}

install_flatpak() {
	if ! command -v flatpak >/dev/null 2>&1; then
		return
	fi

	while IFS= read -r app; do
		flatpak install -y flathub "$app"
	done < <(read_manifest "$repo_root/packages/flatpak.txt")
}

apply_desktop_preferences() {
	if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
		"$repo_root/scripts/.local/bin/apply-gnome-dconf" >/dev/null 2>&1 || true
	fi

}

setup_mise() {
	if ! command -v mise >/dev/null 2>&1; then
		return
	fi

	mise settings add idiomatic_version_file_enable_tools python >/dev/null 2>&1 || true
	MISE_GLOBAL_CONFIG_FILE="$HOME/.mise.toml" mise install
}

setup_user_services() {
	if ! command -v systemctl >/dev/null 2>&1; then
		return
	fi

	if ! systemctl --user show-environment >/dev/null 2>&1; then
		return
	fi

	systemctl --user daemon-reload
	systemctl --user enable backup-repos.timer >/dev/null 2>&1 || true
	systemctl --user enable waybar.service >/dev/null 2>&1 || true
	if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
		systemctl --user restart waybar.service >/dev/null 2>&1 || true
	fi
}

import_local_secrets() {
	"$repo_root/scripts/.local/bin/import-secrets" || true
}

setup_system_services() {
	if ! command -v systemctl >/dev/null 2>&1; then
		return
	fi

	sudo systemctl enable smb.service nmb.service >/dev/null 2>&1 || true
}

backup_conflicting_targets() {
	local target
	local timestamp

	timestamp="$(date +%Y%m%d-%H%M%S)"

	for target in \
		"$HOME/.config/gtk-3.0/settings.ini" \
		"$HOME/.config/gtk-4.0/settings.ini"; do
		if [[ -e "$target" && ! -L "$target" ]]; then
			mv "$target" "$target.bak-$timestamp"
		fi
	done
}

stow_all() {
	local package
	local output_file

	for package in "${stow_packages[@]}"; do
		output_file="$(mktemp)"

		if stow --target="$HOME" --no-folding --simulate --restow "$package" >"$output_file" 2>&1; then
			stow --target="$HOME" --restow "$package"
		else
			printf 'Skipping stow package %s due to existing unmanaged targets\n' "$package" >&2
			python -c 'from pathlib import Path; import sys; [print(line) for line in Path(sys.argv[1]).read_text().splitlines() if line.startswith(("WARNING!", "  *", "Ignoring "))]' "$output_file" >&2
		fi

		rm -f "$output_file"
	done
}

upgrade_system
install_pacman
install_aur
install_flatpak
backup_conflicting_targets
stow_all
import_local_secrets
apply_desktop_preferences
setup_system_services
setup_user_services
setup_mise
install_vscode_extensions
