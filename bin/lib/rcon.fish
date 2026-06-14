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
    test (count $argv) -gt 0; or return 0
    set -l batch 100
    set -l pending
    # `forceload add` must take effect (chunks load) before the fills/setblocks
    # that follow — a build into an unloaded chunk fails. So flush any pending
    # batch, send the forceload on its own connection, and for an `add` poll
    # `execute if loaded` on the far corner until the chunks are really up.
    for cmd in $argv
        if string match -q 'forceload *' -- $cmd
            if set -q pending[1]
                MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c $pending; or return 1
                set -e pending
            end
            MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c $cmd; or return 1
            set -l p (string split ' ' -- $cmd)
            if test "$p[2]" = add; and test (count $p) -ge 6
                for try in (seq 1 60)
                    set -l a (MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c "execute if loaded $p[3] 0 $p[4]")
                    set -l b (MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c "execute if loaded $p[5] 0 $p[6]")
                    string match -q '*passed*' -- "$a"; and string match -q '*passed*' -- "$b"; and break
                end
            end
        else
            set -a pending $cmd
            if test (count $pending) -ge $batch
                MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c $pending; or return 1
                set -e pending
            end
        end
    end
    if set -q pending[1]
        MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS mcrcon -c $pending; or return 1
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

