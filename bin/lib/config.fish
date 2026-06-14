# --- config (~/.config/mc-tui/rcon.conf) --------------------------------------

function load_conf
    set -g HOST localhost
    set -g PORT 25575
    set -g PASS ''
    set -g PLATFORM java_26_1 # chunkbase seed-map platform tag
    set -g INTERVAL 10 # follow-map refresh seconds
    set -g ZOOM 2 # follow-map starting zoom
    set -g STATUS_TTL 10 # seconds to cache the RCON reachability check
    test -r $CONF; or return 0
    while read -l line
        set -l kv (string split -m1 '=' -- $line)
        switch "$kv[1]"
            case host; set -g HOST $kv[2]
            case port; set -g PORT $kv[2]
            case pass; set -g PASS $kv[2]
            case platform; set -g PLATFORM $kv[2]
            case interval; set -g INTERVAL $kv[2]
            case zoom; set -g ZOOM $kv[2]
            case status_ttl; set -g STATUS_TTL $kv[2]
        end
    end <$CONF
end

function save_conf
    mkdir -p $CFGDIR
    printf 'host=%s\nport=%s\npass=%s\nplatform=%s\ninterval=%s\nzoom=%s\nstatus_ttl=%s\n' \
        "$HOST" "$PORT" "$PASS" "$PLATFORM" "$INTERVAL" "$ZOOM" "$STATUS_TTL" >$CONF
    chmod 600 $CONF
end

function ensure_conf
    load_conf
    if test -z "$PASS"
        echo 'RCON password not configured yet — opening [settings]'
        settings_view
        load_conf
        test -n "$PASS"; or return 1
    end
end

