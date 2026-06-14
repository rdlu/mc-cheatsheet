# --- railroad builder ---------------------------------------------------------
# Compile a railroad YAML definition (see plans/railroad-builder.md) into
# commands via scripts/railroad.py, and for `run` stream them over RCON. An
# optional trailing player resolves `from: player` / `dir: auto` from their live
# pose (position + facing).

function rail_script
    echo (path dirname -- (path dirname -- $SELF))/scripts/railroad.py
end

function rail_cli # <compile|run|validate> <file.yml> [player]
    set -l sub $argv[1]
    set -l file $argv[2]
    set -l who $argv[3]
    test -n "$sub" -a -n "$file"; or _die 'usage: mc-tui rail compile|run|validate <file.yml> [player]'
    type -q uv; or _die 'uv is required for the railroad compiler (mise install)'
    set -l script (rail_script)
    test -f $script; or _die "railroad.py not found at $script"

    # resolve a live pose only when a player is named (for from:player / dir:auto)
    set -l poseargs
    if test -n "$who"
        # player_pose echoes one space-separated line; fish command substitution
        # splits on newlines, so split the fields out explicitly.
        set -l pose (player_pose $who | string split ' ')
        test (count $pose) -ge 5; or _die "could not read $who's pose (online?)"
        set poseargs --pose "$pose[2] $pose[3] $pose[4] $pose[5]"
    end

    switch $sub
        case compile
            uv run --quiet $script compile $poseargs -- $file
        case validate
            uv run --quiet $script validate $poseargs -- $file
        case run
            set -l cmds (uv run --quiet $script compile $poseargs -- $file)
            or _die 'compile failed (see message above)'
            test (count $cmds) -gt 0; or _die 'no commands generated'
            test (server_status) != down; or _die 'server offline — not sending'
            printf '%s\n' $cmds
            echo (set_color -d)'-- sending '(count $cmds)' command(s) over RCON --'(set_color normal)
            rcon_exec_many $cmds
        case '*'
            _die "unknown rail subcommand: $sub (use compile|run|validate)"
    end
end

# deck materials — the aesthetically pleasing polished/brick variants
function rail_deck_palette
    printf '%s\n' polished_andesite polished_diorite polished_granite \
        stone_bricks smooth_stone deepslate_bricks deepslate_tiles \
        polished_deepslate polished_blackstone_bricks bricks \
        smooth_sandstone smooth_quartz
end

# subway-style line colors (the under-rail stripe)
function rail_color_palette
    printf '%s\n' none white_concrete light_gray_concrete gray_concrete \
        black_concrete red_concrete orange_concrete yellow_concrete lime_concrete \
        green_concrete light_blue_concrete cyan_concrete blue_concrete \
        purple_concrete magenta_concrete pink_concrete brown_concrete
end

# side-barrier blocks (or none/open)
function rail_wall_palette
    printf '%s\n' none glass tinted_glass iron_bars oak_fence \
        stone_brick_wall deepslate_brick_wall polished_blackstone_brick_wall
end

# light sources for track lighting
function rail_light_palette
    printf '%s\n' lantern soul_lantern sea_lantern glowstone shroomlight \
        end_rod redstone_lamp ochre_froglight
end

function rail_delta --argument-names dir # echoes "dx dz" for a cardinal
    switch $dir
        case north
            echo '0 -1'
        case south
            echo '0 1'
        case east
            echo '1 0'
        case west
            echo '-1 0'
    end
end

# fixed-choice picker that also accepts a typed custom value (like pick_item)
function rail_pick # <prompt> <header> <option...>
    set -l out (printf '%s\n' $argv[3..] | fzf --reverse --height 55% --print-query \
            --prompt "$argv[1]> " --header "$argv[2]")
    test -z "$out[-1]"; and return 1
    echo $out[-1]
end

# preview the compiled commands for a definition file, then run / copy / save
function rail_action_menu # <yaml-file> <id>
    set -l file $argv[1]
    set -l id $argv[2]
    set -l script (rail_script)
    set -l err (mktemp /tmp/mc-tui-rail-err.XXXXXX)
    while true
        set -l cmds (uv run --quiet $script compile $file 2>$err)
        if test $status -ne 0
            echo 'compile failed:'
            cat $err
            pause
            rm -f $err
            return
        end
        set -l n (count $cmds)
        echo "── $id: $n command(s) ──"
        printf '%s\n' $cmds | head -18
        test $n -gt 18; and echo "  … (+"(math "$n - 18")" more)"
        set -l choice (printf '%s\n' \
                'run over RCON' 'copy to clipboard' 'save as YAML' 'cancel' | \
            fzf --reverse --height 40% --prompt 'rail action> ' \
                --header (status_line)\n"$id — $n command(s)")
        switch "$choice"
            case 'run*'
                if test (server_status) = down
                    echo 'server offline — not sending ([status] to re-check)'
                else
                    rcon_exec_many $cmds
                end
                pause
                rm -f $err
                return
            case 'copy*'
                clip (string join \n -- $cmds)
                pause
            case 'save*'
                mkdir -p $CFGDIR/rail
                cp $file $CFGDIR/rail/$id.yml
                echo "saved: $CFGDIR/rail/$id.yml"
                pause
            case '*'
                rm -f $err
                return
        end
    end
end

# the build-a-line wizard: read the player's pose, collect choices, write a
# concrete (reproducible) YAML and hand it to the action menu.
function rail_build_line
    type -q uv; or begin
        echo 'uv is required for the railroad compiler (mise install)'
        pause
        return
    end
    set -l who (pick_player player); or return
    set -l pose (player_pose $who | string split ' ')
    if test (count $pose) -lt 5
        echo "couldn't read $who's position/facing — online? (try again in a moment)"
        pause
        return
    end
    set -l dim $pose[1]
    set -l px $pose[2]
    set -l py $pose[3]
    set -l pz $pose[4]
    set -l facing $pose[5]
    echo "$who is at $px $py $pz in the $dim, facing $facing"

    set -l dirs $facing
    for d in north south east west
        test $d != $facing; and set -a dirs $d
    end
    set -l dir (rail_pick direction "build direction (detected: $facing) — esc cancels" $dirs); or return

    set -l off (fzf_input 'height offset' 'blocks above your feet — 0 = at your level' 0 5 10 20 -5)
    test -n "$off"; or set off 0
    set -l width (rail_pick width 'deck width — 3 (platform) or 1 (minimal)' 3 1); or return
    set -l len (fzf_input length 'rails to lay — pick or type a number' 16 32 64 128 256 8); or return
    set -l deck (rail_pick deck 'deck material (polished/brick) — or type any block' (rail_deck_palette)); or return
    set -l color (rail_pick 'line color' 'subway stripe under the rail — none for plain' (rail_color_palette))
    or set color none
    set -l walls (rail_pick walls 'side barrier — none, or pick/type a block' (rail_wall_palette))
    or set walls none
    set -l lchoice (rail_pick lighting 'track lighting (stops mob spawns) — esc/none = off' none 'poles' 'edge' 'sides of base')
    or set lchoice none
    set -l light none
    set -l lstyle pole
    set -l lspace 8
    if test "$lchoice" != none
        switch "$lchoice"
            case 'edge'
                set lstyle edge
            case 'sides*'
                set lstyle side
            case '*'
                set lstyle pole
        end
        set light (rail_pick 'light block' 'the light source — or type any block' (rail_light_palette))
        or set light lantern
        set lspace (fzf_input 'light spacing' 'blocks between lights — <=24 stops all spawns' 8 6 12 16)
        test -n "$lspace"; or set lspace 8
    end
    set -l estop (rail_pick 'end stop' 'buffer at the far end so the cart cant fly off — esc/none = off' red_concrete none red_wool deepslate_tiles)
    or set estop none
    set -l name (fzf_input 'line name' 'a label for this line (used as the saved filename)' "$dir line")
    test -n "$name"; or set name "$dir line"

    # concrete start: one block ahead of the player in `dir`, at feet + offset
    set -l d (rail_delta $dir | string split ' ')
    set -l sx (math "$px + $d[1]")
    set -l sy (math "$py + $off")
    set -l sz (math "$pz + $d[2]")
    set -l id (string lower -- "$name" | string replace -ra '[^a-z0-9]+' '-' | string trim -c '-')
    test -n "$id"; or set id line

    set -l tmp (mktemp /tmp/mc-tui-rail.XXXXXX.yml)
    begin
        set -l colorpart ''
        test "$color" != none; and set colorpart ", color: $color"
        set -l lightpart ''
        test "$light" != none; and set lightpart ", light: $light, light_style: $lstyle, light_spacing: $lspace"
        set -l estoppart ''
        test "$estop" != none; and set estoppart ", end_stop: $estop"
        echo "line: {id: $id$colorpart}"
        echo "defaults: {width: $width, deck: $deck, walls: $walls, power_spacing: 8$lightpart$estoppart}"
        echo 'segments:'
        echo "  - {from: [$sx, $sy, $sz], dir: $dir, length: $len}"
    end >$tmp
    rail_action_menu $tmp $id
end

# place a single station at the player's position (a length-1 segment carries
# the anchor; the station overwrites it, so only the station shows).
function rail_build_station
    type -q uv; or begin
        echo 'uv is required for the railroad compiler (mise install)'
        pause
        return
    end
    set -l who (pick_player player); or return
    set -l pose (player_pose $who | string split ' ')
    if test (count $pose) -lt 5
        echo "couldn't read $who's position/facing — online?"
        pause
        return
    end
    set -l px $pose[2]
    set -l py $pose[3]
    set -l pz $pose[4]
    set -l facing $pose[5]
    echo "$who is at $px $py $pz, facing $facing"

    set -l dirs $facing
    for d in north south east west
        test $d != $facing; and set -a dirs $d
    end
    set -l dir (rail_pick direction "build direction (detected: $facing) — esc cancels" $dirs); or return
    set -l type (rail_pick 'station type' 'halt = open · covered = roofed · terminus = dead-end buffer at a line end' halt covered terminus); or return
    set -l off (fzf_input 'height offset' 'blocks above your feet — 0 = at your level' 0 5 10 20)
    test -n "$off"; or set off 0
    set -l deck (rail_pick deck 'platform material (polished/brick) — or type any block' (rail_deck_palette)); or return
    set -l color (rail_pick 'accent color' 'marker block — none for plain' (rail_color_palette))
    or set color none
    set -l name (fzf_input 'station name' 'a label (used as the saved filename)' "$type station")
    test -n "$name"; or set name "$type station"

    set -l d (rail_delta $dir | string split ' ')
    set -l sx (math "$px + $d[1]")
    set -l sy (math "$py + $off")
    set -l sz (math "$pz + $d[2]")
    set -l id (string lower -- "$name" | string replace -ra '[^a-z0-9]+' '-' | string trim -c '-')
    test -n "$id"; or set id station

    set -l tmp (mktemp /tmp/mc-tui-rail.XXXXXX.yml)
    begin
        set -l colorpart ''
        test "$color" != none; and set colorpart ", color: $color"
        echo "line: {id: $id$colorpart}"
        echo "defaults: {width: 1, deck: $deck, power_spacing: 8}"
        echo 'segments:'
        echo "  - {from: [$sx, $sy, $sz], dir: $dir, length: 1}"
        echo 'stations:'
        echo "  - {at: start, type: $type}"
    end >$tmp
    rail_action_menu $tmp $id
end

# place a single track switch one block ahead of the player. A length-1 segment
# carries the anchor; the junction overlays it (its approach rail joins the line
# behind you). The lever diverts the next cart down the branch; a detector rail
# past the junction springs it back to the through line.
function rail_build_junction
    type -q uv; or begin
        echo 'uv is required for the railroad compiler (mise install)'
        pause
        return
    end
    set -l who (pick_player player); or return
    set -l pose (player_pose $who | string split ' ')
    if test (count $pose) -lt 5
        echo "couldn't read $who's position/facing — online?"
        pause
        return
    end
    set -l px $pose[2]
    set -l py $pose[3]
    set -l pz $pose[4]
    set -l facing $pose[5]
    echo "$who is at $px $py $pz, facing $facing"

    set -l dirs $facing
    for d in north south east west
        test $d != $facing; and set -a dirs $d
    end
    set -l dir (rail_pick direction "travel direction (detected: $facing) — esc cancels" $dirs); or return
    set -l kind (rail_pick 'junction kind' 't = straight + a side branch · y = two-way fork' t y); or return
    set -l branch (rail_pick branch 'which side the branch peels off (lever diverts here)' right left); or return
    set -l off (fzf_input 'height offset' 'blocks above your feet — 0 = at your level' 0 5 10 20)
    test -n "$off"; or set off 0
    set -l deck (rail_pick deck 'deck material (polished/brick) — or type any block' (rail_deck_palette)); or return
    set -l name (fzf_input 'junction name' 'a label (used as the saved filename)' "$dir $kind switch")
    test -n "$name"; or set name "$dir $kind switch"

    set -l d (rail_delta $dir | string split ' ')
    set -l sx (math "$px + $d[1]")
    set -l sy (math "$py + $off")
    set -l sz (math "$pz + $d[2]")
    set -l id (string lower -- "$name" | string replace -ra '[^a-z0-9]+' '-' | string trim -c '-')
    test -n "$id"; or set id switch

    set -l tmp (mktemp /tmp/mc-tui-rail.XXXXXX.yml)
    begin
        echo "line: {id: $id}"
        echo "defaults: {width: 1, deck: $deck, power_spacing: 8}"
        echo 'segments:'
        echo "  - {from: [$sx, $sy, $sz], dir: $dir, length: 1}"
        echo 'junctions:'
        echo "  - {at: start, kind: $kind, branch: $branch}"
    end >$tmp
    rail_action_menu $tmp $id
end

function rail_load_line
    type -q uv; or begin
        echo 'uv is required for the railroad compiler (mise install)'
        pause
        return
    end
    set -l files (ls $CFGDIR/rail/*.yml 2>/dev/null)
    if test (count $files) -eq 0
        echo "no saved lines yet (build one and choose 'save as YAML')"
        pause
        return
    end
    set -l pick (printf '%s\n' $files | fzf --reverse --height 50% \
        --prompt 'load> ' --header 'saved lines — esc back')
    test -n "$pick"; or return
    set -l id (string replace -r '.*/' '' -- $pick | string replace -r '\.yml$' '')
    rail_action_menu $pick $id
end

function railroad_view
    while true
        set -l hdr (status_line)\n'railroad builder — powered lines + kits, built from where you stand'
        set -l choice (printf '%s\n' \
                'build a line' \
                'place a station' \
                'place a junction' \
                'load a saved line' \
                'materials / corner kit' \
                back | \
            fzf --reverse --height 50% --prompt 'railroad> ' --header $hdr)
        switch "$choice"
            case 'build*'
                rail_build_line
            case 'place a station' 'place a st*'
                rail_build_station
            case 'place a junction' 'place a j*'
                rail_build_junction
            case 'load*'
                rail_load_line
            case 'materials*'
                command_view railroad
            case '*'
                return
        end
    end
end

