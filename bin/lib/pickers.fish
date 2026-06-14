# --- pickers -------------------------------------------------------------------

function pick_player --argument-names what # saved names + selectors, or typed
    set -l out (begin
            saved_players
            printf '%s\n' \
                '@s — yourself (not valid from the RCON console)' \
                '@p — nearest player' \
                '@a — all players' \
                '@r — random player' \
                '@e — all entities'
        end | fzf --reverse --height 60% --print-query --prompt "$what> " \
            --header 'pick a saved name or selector — or type any name and press enter')
    test -z "$out[-1]"; and return 1
    echo (string split -n ' ' -- $out[-1])[1]
end

function pick_item
    set -l out (items | awk -F'|' '{ printf "%-10s %-58s \033[36m%-30s\033[0m \033[2m%s\033[0m\n", $1, $2, $3, $4 }' | \
        fzf --ansi --reverse --print-query --prompt 'item> ' \
            --header 'pick an item (english or português) — or type any item id and press enter')
    test -z "$out[-1]"; and return 1
    set -l toks (string split -n ' ' -- $out[-1])
    test (count $toks) -ge 2; and echo $toks[2]; or echo $toks[1]
end

function pick_from --argument-names dataset label # enchantments, effects, ...
    set -l out (data_$dataset | awk -F'|' '{ printf "%-26s \033[2m%s\033[0m\n", $1, $2 }' | \
        fzf --ansi --reverse --height 70% --print-query --prompt "$label> " \
            --header "pick a $label — or type any id and press enter")
    test -z "$out[-1]"; and return 1
    echo (string split -n ' ' -- $out[-1])[1]
end

# Reliable text/number input via fzf. The plain `read` builtin comes back empty
# inside fill() (command substitution, just after a piped fzf), so use fzf for
# typed values too — it reads /dev/tty like the other pickers. Suggestions are
# passed as args and piped to fzf *in the same command sub* (as pick_from does);
# piping into the function instead lets fzf fall back to its file-finder. Pick a
# suggestion or type a custom value; esc returns nothing.
function fzf_input # <prompt> <header> [suggestion...]
    set -l out (begin
            test (count $argv) -gt 2; and printf '%s\n' $argv[3..]
        end | fzf --reverse --height 40% --print-query \
            --prompt "$argv[1]> " --header "$argv[2]")
    test $status -eq 0; or return 1
    echo $out[-1]
end

# --- placeholder filling -------------------------------------------------------

function fill --argument-names tmpl # <token> -> picker/prompt; <token?> optional
    set -l cmd $tmpl
    while set -l m (string match -r '<([a-z0-9_]+\??)>' -- $cmd)
        set -l tok $m[2]
        set -l name (string trim -r -c '?' -- $tok)
        set -l val
        set -l opt ''
        test "$tok" != "$name"; and set opt ' · esc skips'
        switch $name
            case player target
                set val (pick_player $name)
            case item block block2
                set val (pick_item)
            case enchantment
                set val (pick_from enchantments enchantment)
            case effect
                set val (pick_from effects effect)
            case entity
                set val (pick_from entities entity)
            case structure
                set val (pick_from structures structure)
            case biome
                set val (pick_from biomes biome)
            case count
                set val (fzf_input "$name" "pick a stack size · type any number$opt" 64 32 16 8 2 1)
            case x y z x2 y2 z2 x3 y3 z3
                set val (fzf_input "$name" "coordinate — ~ is relative · type a value$opt" '~')
            case '*'
                set val (fzf_input "$name" "type a value$opt")
        end
        if test -z "$val"
            test "$tok" = "$name"; and return 1 # required -> abort
            set cmd (string replace -- " <$tok>" '' $cmd | string replace -- "<$tok>" '')
        else
            set cmd (string replace -- "<$tok>" $val $cmd)
        end
    end
    echo $cmd
end

# --- previews (invoked by fzf as: mc-tui __preview <line>) ----------------------

function preview_cmd
    # the fzf line is "<template>\t<description>"; take the template, drop any
    # leftover ANSI/padding, and look the row up for the full description.
    set -l tmpl (string split -m1 \t -- $argv[1])[1]
    set tmpl (string replace -ra '\x1b\[[0-9;]*m' '' -- $tmpl | string trim)
    catalog | awk -F'|' -v t="$tmpl" '$2 == t {
        printf "\033[1m%s\033[0m\n\n%s\n", $2, $3; exit
    }'
end

function preview_cat --argument-names cat
    switch $cat
        case '[console]'
            if type -q nmcrcon
                echo 'interactive nmcrcon session using the saved settings'
                echo '(line editing, Ctrl-R history, multi-packet responses)'
            else
                echo 'interactive mcrcon -t session using the saved settings'
            end
        case '[players]'
            echo 'saved player names — offered whenever a command needs a <player>'
            echo
            saved_players
        case '[map]'
            echo 'open the world on chunkbase.com/apps/seed-map'
            echo '- reads the seed over RCON'
            echo '- centers on spawn, given coords, or a live player position'
            echo '- FOLLOW: a Chromium window that tracks a player every 10s'
            echo '- needs the version tag (platform) from [settings]'
        case '[rail builder]'
            echo 'build surface/air railroads from where you stand:'
            echo '- reads your position + facing over RCON'
            echo '- always-powered lines, width 1 or 3, your stone palette + line color'
            echo '- compiles to fill/setblock, streamed over RCON (preview/run/copy/save)'
            echo '- "materials / corner kit" gives the rails, redstone + deck blocks'
            echo
            echo 'saved lines live in '$CFGDIR/rail/' (also: mc-tui rail <compile|run> file.yml)'
        case '[settings]'
            load_conf
            echo "host      $HOST"
            echo "port      $PORT"
            echo 'pass      '(test -n "$PASS"; and echo '(set)'; or echo '(not set)')
            echo "platform  $PLATFORM"
            echo "interval  $INTERVAL s (follow map)"
            echo "zoom      $ZOOM (follow map start)"
            echo
            echo "config: $CONF"
        case '*'
            catalog | awk -F'|' -v c="$cat" '$1 == c { print $2 }'
    end
end

