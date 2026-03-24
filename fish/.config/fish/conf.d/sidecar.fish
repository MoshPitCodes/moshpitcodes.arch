function sc --wraps sidecar --description 'Run sidecar'
    command sidecar $argv
end

if status is-interactive
    abbr --add sc sidecar
end
