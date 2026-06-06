# World control

Game modes, time & weather, gamerules, building, and entities.

## Game mode & difficulty

| Command | Effect |
| --- | --- |
| `gamemode creative` | also: `survival`, `adventure`, `spectator` |
| `gamemode survival Alice` | for another player |
| `defaultgamemode survival` | for new players |
| `difficulty hard` | `peaceful` `easy` `normal` `hard` |

## Time & weather

| Command | Effect |
| --- | --- |
| `time set day` | also: `noon`, `night`, `midnight` |
| `time set 1000` | ticks (24000 = full day) |
| `time add 1000` | advance time |
| `time query time` | current clock ticks |
| `time pause` / `time resume` | freeze / unfreeze the clock (26.1+) |
| `weather clear` | also: `rain`, `thunder` |
| `weather rain 600` | duration in seconds |

!!! note "Pre-26 versions"
    Before 26.1 the query form was `time query daytime`, and
    `time pause`/`resume` didn't exist (freeze with
    `gamerule doDaylightCycle false` instead).

## Useful gamerules

| Command | Effect |
| --- | --- |
| `gamerule keep_inventory true` | no item loss on death |
| `gamerule mob_griefing false` | no creeper/enderman damage |
| `gamerule advance_time false` | freeze time |
| `gamerule advance_weather false` | freeze weather |
| `gamerule spawn_mobs false` | no hostile spawns |
| `gamerule players_sleeping_percentage 1` | one sleeper skips night |
| `gamerule random_tick_speed 3` | crop growth speed (default 3) |

Run `gamerule <name>` with no value to query the current setting —
`help gamerule` lists all 62 (the reply overflows mcrcon's packet limit;
use `nmcrcon` or the server console for it).

!!! note "Pre-26 versions"
    Gamerules were camelCase before 26.1: `keepInventory`, `mobGriefing`,
    `doDaylightCycle`, `doWeatherCycle`, `doMobSpawning`
    (now `spawn_mobs`), `playersSleepingPercentage`, `randomTickSpeed`,
    `spawnRadius` (now `respawn_radius`), `doFireTick`
    (now `fire_spread_radius_around_player`).

## Building

| Command | Effect |
| --- | --- |
| `setblock ~ ~ ~ stone` | place one block |
| `fill 0 64 0 10 70 10 glass` | fill region (max 32 768 blocks) |
| `fill 0 64 0 10 70 10 air` | clear a region |

```text
fill 0 64 0 10 70 10 stone replace dirt   # replace only dirt
clone 0 64 0 10 70 10 50 64 50            # copy region to new corner
```

The two corner coordinates of `fill`/`clone` are inclusive; `clone`'s third
coordinate is the **lowest-X/Y/Z corner** of the destination.

## Entities & world

| Command | Effect |
| --- | --- |
| `summon zombie ~ ~ ~` | spawn an entity |
| `summon lightning_bolt` | smite current spot |
| `kill @e[type=item]` | clear dropped items (lag) |
| `kill @e[type=zombie,distance=..20]` | nearby zombies |
| `locate structure village_plains` | coords of nearest (or any village: `#minecraft:village`) |
| `locate biome cherry_grove` | nearest biome |
| `seed` | show world seed |

!!! warning "`kill @e` kills *everything*"
    Including players, item frames, and armor stands. Always filter by
    `type=` (or at least `type=!player`).

!!! tip "locate over RCON searches the overworld"
    RCON has no position *or* dimension. For nether/end structures, wrap
    it: `execute in minecraft:the_nether run locate structure fortress`.
