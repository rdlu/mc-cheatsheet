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
| `time query daytime` | current time of day |
| `weather clear` | also: `rain`, `thunder` |
| `weather rain 600` | duration in seconds |

## Useful gamerules

| Command | Effect |
| --- | --- |
| `gamerule keepInventory true` | no item loss on death |
| `gamerule mobGriefing false` | no creeper/enderman damage |
| `gamerule doDaylightCycle false` | freeze time |
| `gamerule doWeatherCycle false` | freeze weather |
| `gamerule doMobSpawning false` | no hostile spawns |
| `gamerule playersSleepingPercentage 1` | one sleeper skips night |
| `gamerule randomTickSpeed 3` | crop growth speed (default 3) |

Run `gamerule <name>` with no value to query the current setting.

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
| `locate structure village` | coords of nearest |
| `locate biome cherry_grove` | nearest biome |
| `seed` | show world seed |

!!! warning "`kill @e` kills *everything*"
    Including players, item frames, and armor stands. Always filter by
    `type=` (or at least `type=!player`).
