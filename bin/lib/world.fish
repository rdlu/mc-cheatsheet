# --- chunkbase seed map -------------------------------------------------------
# Open the world on chunkbase.com, optionally centered on a player's position.
# The map needs the seed (fetched over RCON) and the version tag (PLATFORM in
# [settings], e.g. java_26_1). Player coords come from `data get entity`.

function chunkbase_url --argument-names seed dim x z
    printf 'https://www.chunkbase.com/apps/seed-map#seed=%s&platform=%s&dimension=%s&x=%s&z=%s&zoom=0.5\n' \
        $seed $PLATFORM $dim $x $z
end

function open_url --argument-names url
    if set -q DISPLAY; or set -q WAYLAND_DISPLAY; and type -q xdg-open
        echo "opening: $url"
        xdg-open $url >/dev/null 2>&1 &
        disown
    else
        # headless / over ssh — clipboard is the next best thing
        clip $url
    end
end

# world seed, cached for the session
function world_seed
    set -q SEED_CACHE; and test -n "$SEED_CACHE"; and echo $SEED_CACHE; and return
    set -l out (rcon_exec seed 2>&1 | string join ' ')
    set -l m (string match -r '\[(-?[0-9]+)\]' -- $out)
    test (count $m) -ge 2; or return 1
    set -g SEED_CACHE $m[2]
    echo $m[2]
end

# echoes "<dim> <x> <z>" for an online player, or fails.
# Retries briefly: right after joining (or a dimension change) the player
# entity isn't queryable yet — `data get` returns "No entity was found" for
# a second or two before it settles.
function player_loc --argument-names who
    for attempt in 1 2 3
        set -l pos (rcon_exec "data get entity $who Pos" 2>&1 | string join ' ')
        set -l m (string match -r '\[\s*(-?[0-9.]+)d,\s*(-?[0-9.]+)d,\s*(-?[0-9.]+)d' -- $pos)
        if test (count $m) -ge 4
            set -l x (math -s0 "round($m[2])")
            set -l z (math -s0 "round($m[4])")
            set -l dimraw (rcon_exec "data get entity $who Dimension" 2>&1 | string join ' ')
            set -l dim overworld
            string match -q '*the_nether*' -- $dimraw; and set dim nether
            string match -q '*the_end*' -- $dimraw; and set dim end
            echo $dim $x $z
            return 0
        end
        test "$attempt" -lt 3; and sleep 1
    end
    return 1
end

# Minecraft yaw -> cardinal facing. MC yaw: 0 = south (+Z), 90 = west (-X),
# 180 = north (-Z), 270 = east (+X). Snap to the nearest of the four: shift by
# 45, take 90-degree buckets, mod 4. Handles negative and >360 yaws.
function yaw_to_dir --argument-names yaw
    set -l n (math -s0 "floor(((($yaw % 360) + 360) % 360 + 45) / 90) % 4")
    switch $n
        case 0
            echo south
        case 1
            echo west
        case 2
            echo north
        case '*'
            echo east
    end
end

# echoes "<dim> <x> <y> <z> <dir>" for an online player, or fails. Like
# player_loc but also returns the feet-block Y and the cardinal facing (from
# Rotation's yaw), for the railroad builder. Same brief retry: the entity isn't
# queryable for a second or two right after joining or changing dimension.
function player_pose --argument-names who
    for attempt in 1 2 3
        set -l pos (rcon_exec "data get entity $who Pos" 2>&1 | string join ' ')
        set -l m (string match -r '\[\s*(-?[0-9.]+)d,\s*(-?[0-9.]+)d,\s*(-?[0-9.]+)d' -- $pos)
        if test (count $m) -ge 4
            set -l x (math -s0 "floor($m[2])")
            set -l y (math -s0 "floor($m[3])") # feet block = rail (riding) level
            set -l z (math -s0 "floor($m[4])")
            set -l rot (rcon_exec "data get entity $who Rotation" 2>&1 | string join ' ')
            set -l ry (string match -r '\[\s*(-?[0-9.]+)f' -- $rot)
            set -l dir south
            test (count $ry) -ge 2; and set dir (yaw_to_dir $ry[2])
            set -l dimraw (rcon_exec "data get entity $who Dimension" 2>&1 | string join ' ')
            set -l dim overworld
            string match -q '*the_nether*' -- $dimraw; and set dim nether
            string match -q '*the_end*' -- $dimraw; and set dim end
            echo $dim $x $y $z $dir
            return 0
        end
        test "$attempt" -lt 3; and sleep 1
    end
    return 1
end

