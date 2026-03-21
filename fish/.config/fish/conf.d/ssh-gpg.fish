## Runtime agent wiring only. Secret material is imported separately by `import-secrets`.
set -l gpg_ssh_socket (gpgconf --list-dirs agent-ssh-socket 2>/dev/null)

if test -n "$gpg_ssh_socket"
    gpgconf --launch gpg-agent >/dev/null 2>&1

    if test -S "$gpg_ssh_socket"
        set -gx SSH_AUTH_SOCK "$gpg_ssh_socket"
    end
end

if status is-interactive
    set -gx GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1

    if set -q SSH_AUTH_SOCK
        if not ssh-add -l >/dev/null 2>&1
            for keydir in ~/.ssh
                if test -d "$keydir"
                    for keyfile in "$keydir"/id_ed25519_*
                        if test -f "$keyfile"; and not string match -q '*.pub' -- "$keyfile"
                            ssh-add "$keyfile" >/dev/null 2>&1
                        end
                    end
                end
            end
        end
    end
end
