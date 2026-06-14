# --- views ----------------------------------------------------------------------

function settings_view
    while true
        load_conf
        set -l masked '(not set)'
        test -n "$PASS"; and set masked (string repeat -n (string length -- $PASS) '*')
        set -l choice (printf '%s\n' \
                "host      $HOST" \
                "port      $PORT" \
                "password  $masked" \
                "platform  $PLATFORM" \
                "follow interval  $INTERVAL s" \
                "follow zoom      $ZOOM" \
                "status cache     $STATUS_TTL s" \
                'test connection (runs list)' \
                back | fzf --reverse --height 50% --prompt 'settings> ' \
                --header "RCON is plaintext — localhost / LAN / ssh tunnel only · saved to $CONF (600)")
        switch "$choice"
            case 'host*'
                read -lP "host [$HOST]> " v
                test -n "$v"; and set -g HOST $v
                save_conf
            case 'port*'
                read -lP "port [$PORT]> " v
                test -n "$v"; and set -g PORT $v
                save_conf
            case 'password*'
                read -slP 'password (hidden)> ' v
                echo
                test -n "$v"; and set -g PASS $v
                save_conf
                status_refresh >/dev/null
            case 'platform*'
                echo 'chunkbase seed-map version tag, e.g. java_26_1, java_1_21, bedrock_1_21'
                read -lP "platform [$PLATFORM]> " v
                test -n "$v"; and set -g PLATFORM $v
                save_conf
            case 'follow interval*'
                echo 'seconds between follow-map updates (lower = more reload flicker)'
                read -lP "interval [$INTERVAL]> " v
                if string match -rq '^[0-9]+(\.[0-9]+)?$' -- "$v"
                    set -g INTERVAL $v
                    save_conf
                else if test -n "$v"
                    echo 'must be a number'
                    pause
                end
            case 'follow zoom*'
                echo 'chunkbase starting zoom (you can still scroll to change it live)'
                read -lP "zoom [$ZOOM]> " v
                if string match -rq '^[0-9]+(\.[0-9]+)?$' -- "$v"
                    set -g ZOOM $v
                    save_conf
                else if test -n "$v"
                    echo 'must be a number'
                    pause
                end
            case 'status cache*'
                echo 'seconds to cache the server status check (lower = pings more often)'
                read -lP "status cache ttl [$STATUS_TTL]> " v
                if string match -rq '^[0-9]+$' -- "$v"
                    set -g STATUS_TTL $v
                    save_conf
                else if test -n "$v"
                    echo 'must be a whole number'
                    pause
                end
            case 'test*'
                rcon_exec list
                status_refresh >/dev/null
                pause
            case '*'
                return
        end
    end
end

# Interactive entry for `mc-tui follow` (no args): pick a connected player,
# ask the refresh interval, then start the live map.
function follow_interactive
    set -l names (online_players)
    if test (count $names) -eq 0
        echo 'nobody is online right now (or the server is unreachable)'
        pause
        return 1
    end
    set -l who (printf '%s\n' $names | fzf --reverse --height 40% \
        --prompt 'follow which player> ' \
        --header (count $names)' online — pick one, esc to cancel')
    test -n "$who"; or return 1
    read -lP "update every how many seconds? [$INTERVAL]> " secs
    test -n "$secs"; or set secs $INTERVAL
    if not string match -rq '^[0-9]+(\.[0-9]+)?$' -- "$secs"
        echo "not a number: $secs"
        pause
        return 1
    end
    follow_player $who $secs
end

# Live "follow map": open chunkbase in a Chromium window and re-center it on
# the player's RCON position every few seconds (driven by scripts/follow-map.py
# over the DevTools protocol — chunkbase only reads the view from the URL on
# load, so each update reloads the tab).
function follow_player --argument-names who interval
    set -l root (path dirname -- (path dirname -- $SELF))
    set -l script $root/scripts/follow-map.py
    test -f $script; or begin
        echo "follow-map.py not found at $script"
        pause
        return 1
    end
    type -q uv; or begin
        echo 'uv is required for the live follow map (mise run setup)'
        pause
        return 1
    end
    type -q chromium; or begin
        echo 'chromium is required for the live follow map'
        pause
        return 1
    end
    set -l seed (world_seed)
    test -n "$seed"; or begin
        echo 'could not read the world seed over RCON'
        pause
        return 1
    end
    test -n "$interval"; or set interval $INTERVAL
    echo "following $who on chunkbase every "$interval"s — close the window or Ctrl-C to stop"
    uv run --quiet $script --mc-tui $SELF --player $who \
        --seed $seed --platform $PLATFORM --interval $interval --zoom $ZOOM
end

function map_view
    load_conf
    set -l seed (world_seed)
    if test -z "$seed"
        echo 'could not read the world seed over RCON — check [settings]'
        pause
        return
    end
    while true
        set -l choice (printf '%s\n' \
                'open at spawn (0, 0)' \
                'center on a player (live position)' \
                'FOLLOW a player (live map, auto-updates)' \
                'open at coordinates…' \
                'open the nether' \
                'open the end' \
                "copy seed ($seed)" \
                "platform: $PLATFORM" \
                back | fzf --reverse --height 55% --prompt 'map> ' \
                --header "chunkbase seed map · seed $seed · $PLATFORM")
        switch "$choice"
            case 'open at spawn*'
                open_url (chunkbase_url $seed overworld 0 0)
                pause
            case 'center on a player*'
                set -l who (pick_player player); or continue
                set -l loc (player_loc $who)
                if test (count $loc) -lt 3
                    echo "couldn't read $who's position — offline, or still"
                    echo "spawning in? (`list` shows who's on). Try again in a moment."
                    pause
                    continue
                end
                echo "$who is at $loc[2] $loc[3] in the $loc[1]"
                open_url (chunkbase_url $seed $loc[1] $loc[2] $loc[3])
                pause
            case 'FOLLOW a player*'
                follow_interactive
            case 'open at coordinates*'
                read -lP 'x> ' x
                read -lP 'z> ' z
                test -n "$x" -a -n "$z"; or continue
                open_url (chunkbase_url $seed overworld $x $z)
                pause
            case 'open the nether*'
                open_url (chunkbase_url $seed nether 0 0)
                pause
            case 'open the end*'
                open_url (chunkbase_url $seed end 0 0)
                pause
            case 'copy seed*'
                clip $seed
                pause
            case 'platform:*'
                read -lP "platform tag [$PLATFORM]> " v
                test -n "$v"; and set -g PLATFORM $v; and save_conf
            case '*'
                return
        end
    end
end

function action_menu --argument-names cmd
    while true
        # when the server is offline, drop the RCON actions entirely — only
        # copy / edit / refresh remain. unconfigured still offers run, since
        # rcon_exec will open [settings] to get a password.
        set -l state (server_status)
        set -l opts
        if test "$state" = down
            set opts 'copy to clipboard' 'edit command first' 'refresh status'
        else
            set opts 'run over RCON' 'copy to clipboard' 'run + copy' 'edit command first'
        end
        set -l hdr (status_line)\n"$cmd"
        set -l choice (printf '%s\n' $opts cancel | \
            fzf --ansi --reverse --height 45% --prompt 'action> ' \
                --header $hdr)
        switch "$choice"
            case 'run over*'
                rcon_exec $cmd
                pause
                return
            case 'copy to*'
                clip $cmd
                pause
                return
            case 'run +*'
                clip $cmd
                rcon_exec $cmd
                pause
                return
            case 'edit*'
                read -lP 'command> ' -c "$cmd" edited
                test -n "$edited"; and set cmd $edited
            case 'refresh*'
                status_refresh >/dev/null
            case '*'
                return
        end
    end
end

function command_view --argument-names cat
    while true
        # template and description are tab-separated: fzf strips the ANSI but
        # keeps the tab, so the template comes back clean even when it's longer
        # than the display column (e.g. the god-gear give commands).
        set -l hdr (status_line)\n"$cat | enter: fill + action menu | ctrl-y fill + copy | ctrl-r fill + run | esc back"
        set -l out (catalog | \
            awk -F'|' -v c="$cat" '$1 == c { printf "%-62s\t\033[2m%s\033[0m\n", $2, $3 }' | \
            fzf --ansi --reverse --expect=ctrl-y,ctrl-r \
                --header $hdr \
                --prompt "$cat> " \
                --preview "$SELF __preview {}" --preview-window 'bottom,4,wrap')
        test (count $out) -lt 2; and return
        set -l key $out[1]
        set -l tmpl (string trim -- (string split -m1 \t -- $out[2])[1])
        set -l cmd (fill $tmpl); or continue
        switch "$key"
            case ctrl-y
                clip $cmd
                pause
            case ctrl-r
                if test (server_status) = down
                    echo 'server offline — not sending ([status] on the main menu to re-check)'
                else
                    rcon_exec $cmd
                end
                pause
            case '*'
                action_menu $cmd
        end
    end
end


function main
    command -v fzf >/dev/null; or _die 'fzf is required'
    while true
        set -l hdr (status_line)\n'enter: browse | esc: quit'
        set -l out (begin
                catalog | awk -F'|' '
                    !seen[$1]++ { order[++n] = $1 }
                    { cnt[$1]++ }
                    END { for (i = 1; i <= n; i++)
                        printf "%-18s \033[2m%d commands\033[0m\n", order[i], cnt[order[i]] }'
                printf '%-18s \033[36m%s\033[0m\n' \
                    '[console]' 'interactive RCON session (nmcrcon / mcrcon -t)' \
                    '[map]' 'open the world on chunkbase (seed / player position)' \
                    '[rail builder]' 'build powered rail lines from where you stand' \
                    '[players]' 'saved names for <player> slots' \
                    '[status]' 're-check the server connection now' \
                    '[settings]' 'RCON host / port / password'
            end | fzf --ansi --reverse \
            --header $hdr --prompt 'mc-tui> ' \
            --preview "$SELF __catpreview {}" --preview-window 'right,45%,wrap')
        test -z "$out"; and break
        set -l choice (string replace -r '  +.*$' '' -- $out | string trim)
        switch $choice
            case '[console]'
                if test (server_status) = down
                    echo 'server offline — RCON console unavailable ([status] to re-check)'
                    pause
                else
                    rcon_term
                end
            case '[status]'
                status_refresh >/dev/null
            case '[map]'
                map_view
            case '[rail builder]'
                railroad_view
            case '[players]'
                players_view
            case '[settings]'
                settings_view
            case '*'
                command_view $choice
        end
    end
end

