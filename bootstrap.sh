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
	local line

	while IFS= read -r line || [[ -n "$line" ]]; do
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"

		if [[ -z "$line" || "$line" == \#* ]]; then
			continue
		fi

		printf '%s\n' "$line"
	done <"$file"
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
		# Install manifest apps to the user Flatpak installation so unattended
		# bootstrap runs stay deterministic when remotes like flathub exist in
		# both user and system scopes.
		flatpak install --user -y flathub "$app"
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

has_directory_parents() {
	local target="$1"
	local parent

	parent="$(dirname "$target")"
	while [[ "$parent" != "$HOME" && "$parent" != "/" ]]; do
		if [[ -e "$parent" && ! -d "$parent" ]]; then
			printf 'Cannot reconcile %s because parent path %s is not a directory; leaving target unchanged so stow can skip safely\n' "$target" "$parent" >&2
			return 1
		fi
		parent="$(dirname "$parent")"
	done

	if [[ -e "$HOME" && ! -d "$HOME" ]]; then
		printf 'Cannot reconcile %s because HOME path %s is not a directory\n' "$target" "$HOME" >&2
		return 1
	fi

	return 0
}

reconcile_known_target() {
	local package="$1"
	local relative_target="$2"
	local source="$repo_root/$package/$relative_target"
	local target="$HOME/$relative_target"
	local backup_target="$target.bootstrap-unmanaged.bak"
	local target_realpath
	local source_realpath

	if [[ ! -e "$source" ]]; then
		return 0
	fi

	if ! has_directory_parents "$target"; then
		return 0
	fi

	if [[ ! -e "$target" && ! -L "$target" ]]; then
		return 0
	fi

	if [[ -L "$target" ]]; then
		target_realpath="$(readlink -f -- "$target" 2>/dev/null || true)"
		source_realpath="$(readlink -f -- "$source")"
		if [[ -n "$target_realpath" && "$target_realpath" == "$source_realpath" ]]; then
			return 0
		fi
	fi

	if cmp -s -- "$target" "$source"; then
		rm -f -- "$target"
		return 0
	fi

	mkdir -p -- "$(dirname "$backup_target")"
	mv -f -- "$target" "$backup_target"
}

reconcile_known_stow_conflicts() {
	reconcile_known_target micro .config/micro/settings.json
	reconcile_known_target micro .config/micro/bindings.json
	reconcile_known_target micro .config/micro/colorschemes/everforest.micro
	reconcile_known_target micro .config/micro/colorschemes/tokyonight-night.micro
	reconcile_known_target micro .config/micro/syntax/asm.yaml
	reconcile_known_target xdg .config/mimeapps.list
	reconcile_known_target xdg .config/fontconfig/fonts.conf
	reconcile_known_target xdg .local/share/applications/waypaper.desktop
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
			while IFS= read -r line || [[ -n "$line" ]]; do
				case "$line" in
				WARNING\!* | '  '*'Ignoring '*)
					printf '%s\n' "$line" >&2
					;;
				esac
			done <"$output_file"
		fi

		rm -f "$output_file"
	done
}

upgrade_system
install_pacman
install_aur
install_flatpak
backup_conflicting_targets
reconcile_known_stow_conflicts
stow_all
import_local_secrets
apply_desktop_preferences
setup_system_services
setup_user_services
setup_mise
install_vscode_extensions
