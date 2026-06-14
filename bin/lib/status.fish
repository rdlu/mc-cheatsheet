# --- server status (cached RCON reachability) --------------------------------
# A lightweight `list` over RCON tells us the server is reachable AND the
# password is right. The result is cached in $STATUS_CACHE for $STATUS_TTL
# seconds (keyed by host:port, so changing the connection invalidates it) so
# navigating the menus doesn't hammer the server. State is one of:
#   up | down | unconfigured

set -g STATUS_CACHE $CFGDIR/.status

function status_probe # real check, no cache. echoes up|down|unconfigured
    type -q mcrcon; or begin
        echo down
        return
    end
    load_conf
    test -n "$PASS"; or begin
        echo unconfigured
        return
    end
    set -l runner # bound the connect so an unreachable host can't hang the UI
    type -q timeout; and set runner timeout 3
    if MCRCON_HOST=$HOST MCRCON_PORT=$PORT MCRCON_PASS=$PASS $runner mcrcon -c list >/dev/null 2>&1
        echo up
    else
        echo down
    end
end

function server_status # cached state: up|down|unconfigured
    load_conf
    if test -r $STATUS_CACHE
        set -l parts (string split ' ' -- (cat $STATUS_CACHE))
        if test (count $parts) -ge 3 -a "$parts[3]" = "$HOST:$PORT"
            set -l age (math (date +%s) - $parts[1])
            if test "$age" -ge 0 -a "$age" -lt "$STATUS_TTL"
                echo $parts[2]
                return
            end
        end
    end
    set -l state (status_probe)
    mkdir -p $CFGDIR
    printf '%s %s %s\n' (date +%s) $state "$HOST:$PORT" >$STATUS_CACHE
    echo $state
end

function status_refresh # force a re-probe, update the cache, echo the state
    rm -f $STATUS_CACHE
    server_status
end

function status_badge --argument-names state # colored one-word badge
    switch "$state"
        case up
            echo (set_color green)'● online'(set_color normal)
        case down
            echo (set_color red)'● offline'(set_color normal)
        case unconfigured
            echo (set_color yellow)'● not configured'(set_color normal)
        case '*'
            echo (set_color -d)'● unknown'(set_color normal)
    end
end

function status_line # host:port + badge, for fzf headers
    set -l state (server_status)
    echo "$HOST:$PORT  "(status_badge $state)
end

