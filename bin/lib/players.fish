# --- players (~/.config/mc-tui/players) ---------------------------------------

function saved_players
    test -r $PLAYERS; and cat $PLAYERS
end

function add_player --argument-names name
    test -n "$name"; or return
    mkdir -p $CFGDIR
    begin
        saved_players
        echo $name
    end | sort -u >$PLAYERS.tmp
    mv $PLAYERS.tmp $PLAYERS
end

# currently-online player names, one per line (parsed from `list`)
function online_players
    set -l out (rcon_exec list 2>&1 | string join ' ')
    set -l names (string match -r 'online:\s*(\S.*)$' -- $out)[2]
    test -n "$names"; or return 1
    string split ',' -- $names | string trim | string match -rv '^$'
end

function fetch_players # parse `list` over RCON into the players file
    set -l names (online_players)
    if test (count $names) -eq 0
        echo 'nobody online (or list failed)'
        return 1
    end
    for n in $names
        add_player $n
    end
    echo "saved: "(string join ', ' -- $names)
end

function players_view
    while true
        set -l lines (saved_players)
        test (count $lines) -eq 0; and set lines '(no saved players yet — ctrl-f or ctrl-a)'
        set -l out (printf '%s\n' $lines | fzf --reverse --multi \
            --expect=ctrl-f,ctrl-a,ctrl-d \
            --header 'ctrl-f fetch online via RCON | ctrl-a add a name | ctrl-d delete selected | esc back' \
            --prompt 'players> ')
        test (count $out) -eq 0; and return
        switch "$out[1]"
            case ctrl-f
                fetch_players
                pause
            case ctrl-a
                read -lP 'player name> ' name
                add_player $name
            case ctrl-d
                set -l keep
                for line in (saved_players)
                    contains -- $line $out[2..]; or set -a keep $line
                end
                if test (count $keep) -gt 0
                    printf '%s\n' $keep >$PLAYERS
                else
                    test -r $PLAYERS; and rm $PLAYERS
                end
            case ''
                return
        end
    end
end

