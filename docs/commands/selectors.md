# Selectors & coordinates

The building blocks every other command uses: *who* (target selectors) and
*where* (coordinates).

## Target selectors

| Selector | Targets |
| --- | --- |
| `@p` | nearest player |
| `@a` | all players |
| `@r` | random player |
| `@e` | all entities |
| `@s` | the command's executor (yourself) |

### Filters

Selectors take bracketed filters, combined with `,`:

```text
@e[type=zombie,distance=..10,limit=3,sort=nearest]
@a[gamemode=survival]
@e[type=item]
```

Common filter keys:

| Filter | Meaning |
| --- | --- |
| `type=zombie` | entity type (`!zombie` negates) |
| `distance=..10` | within 10 blocks (`5..` = beyond 5, `5..10` = range) |
| `limit=3` | at most 3 targets |
| `sort=nearest` | also: `furthest`, `random`, `arbitrary` |
| `gamemode=survival` | players in that game mode |
| `name=Alice` | exact entity/player name |

!!! tip "Over RCON"
    Commands run over RCON have **no position**, so `@p`, `@s` and
    relative coordinates behave as if at the world spawn (or fail).
    Prefer explicit player names or `@a[...]` filters from the console.

## Coordinates

| Form | Meaning |
| --- | --- |
| `100 64 -200` | absolute X Y Z |
| `~ ~ ~` | relative to executor (`~5` = +5) |
| `~ ~10 ~` | 10 blocks above current spot |
| `^ ^ ^5` | local: 5 blocks in facing direction |

- **X** runs east (+) / west (−), **Z** south (+) / north (−), **Y** is height.
- `~` (tilde) offsets are world-axis-aligned; `^` (caret) offsets follow the
  executor's facing — `^ ^ ^5` is "5 blocks forward".
- Press <kbd>F3</kbd> in-game to see your coordinates (`XYZ:` line).
