# Teleporting

| Command | Effect |
| --- | --- |
| `tp Alice Bob` | Alice → Bob |
| `tp @s 100 64 -200` | yourself → coords |
| `tp @s ~ ~20 ~` | 20 blocks straight up |
| `tp @a @s` | everyone → you |
| `tp @s 0 64 0 90 0` | with facing (yaw pitch) |

- **Yaw**: 0 = south, 90 = west, 180/−180 = north, −90 = east.
  **Pitch**: 0 = level, 90 = straight down, −90 = straight up.
- `teleport` is the same command; `tp` is the short alias.
- Teleporting into solid blocks suffocates the target — when in doubt,
  aim a couple of blocks high and fall.

## Spawn points

| Command | Effect |
| --- | --- |
| `spawnpoint @s ~ ~ ~` | set respawn point here (per player) |
| `setworldspawn 0 64 0` | set world spawn (new players, no-bed respawns) |

!!! tip "Rescue teleport"
    Player lost or stuck? `tp Alice 0 80 0` from the console drops them
    near spawn — or `tp Alice Bob` to bring them to a buddy.
