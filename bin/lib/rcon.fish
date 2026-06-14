# --- rcon / clipboard ---------------------------------------------------------

function rcon_exec # one command (single argument)
    type -q mcrcon; or begin
        echo 'mcrcon not installed (mise run setup)' >&2
        return 1
    end
    ensure_conf; or return 1
    echo (set_color -d)"rcon($HOST:$PORT)> $argv[1]"(set_color normal)
    MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c $argv[1]
end

# Send many commands over a single mcrcon connection — each argument is one
# command (mcrcon runs positional args sequentially). One connect for the whole
# batch beats one-per-command on a remote server. Chunked so a huge build can't
# overflow argv or a single response. Used by the railroad builder.
function rcon_exec_many # each argument is one command
    type -q mcrcon; or begin
        echo 'mcrcon not installed (mise run setup)' >&2
        return 1
    end
    ensure_conf; or return 1
    set -l n (count $argv)
    test $n -gt 0; or return 0
    set -l batch 100
    set -l i 1
    while test $i -le $n
        set -l j (math "$i + $batch - 1")
        test $j -gt $n; and set j $n
        MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c $argv[$i..$j]; or return 1
        set i (math "$j + 1")
    end
end

# Interactive console: prefer nmcrcon (line editing, Ctrl-R history,
# correct multi-packet responses) and fall back to mcrcon -t. One-shot
# commands (rcon_exec) stay on mcrcon — nmcrcon has no one-shot mode yet.
function rcon_term
    ensure_conf; or return 1
    if type -q nmcrcon
        echo 'interactive RCON (nmcrcon) — arrows + Ctrl-R history; exit or Ctrl-D to quit'
        set -q NMCRCON_HISTORY; or set -lx NMCRCON_HISTORY $HOME/.local/state/nmcrcon-history
        mkdir -p (path dirname -- $NMCRCON_HISTORY)
        MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS nmcrcon
    else
        echo 'interactive RCON (mcrcon) — type commands, Q or Ctrl-D to quit'
        MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -t
    end
end

function clip --argument-names cmd
    if type -q wl-copy
        printf %s $cmd | wl-copy
    else if type -q xclip
        printf %s $cmd | xclip -selection clipboard
    else if type -q xsel
        printf %s $cmd | xsel -ib
    else
        echo 'no clipboard tool found (install wl-clipboard or xclip)' >&2
        return 1
    end
    echo "copied: $cmd"
end

function pause
    read -P (set_color -d)'-- enter to continue --'(set_color normal) >/dev/null
end

