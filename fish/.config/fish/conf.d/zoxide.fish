if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
end

if status is-interactive
    abbr --add cd z
end
