if command -v fd >/dev/null 2>&1
    set -gx FZF_DEFAULT_COMMAND 'fd --hidden --strip-cwd-prefix --exclude .git'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_ALT_C_COMMAND 'fd --type=d --hidden --strip-cwd-prefix --exclude .git'
end

set -gx FZF_DEFAULT_OPTS "--color=fg:-1,fg+:#c0caf5,bg:-1,bg+:#292e42 --color=hl:#7aa2f7,hl+:#7aa2f7,info:#7dcfff,marker:#e0af68 --color=prompt:#f7768e,spinner:#73daca,pointer:#bb9af7,header:#7dcfff --color=border:#414868,label:#565f89,query:#c0caf5 --border=double --border-label='' --preview-window=border-sharp --prompt='> ' --marker='>' --pointer='>' --separator='-' --scrollbar='|' --info=right"
set -gx FZF_CTRL_T_OPTS "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --color=always {} | head -200'"
