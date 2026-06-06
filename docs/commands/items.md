# Items, enchants & XP

## Giving items

| Command | Effect |
| --- | --- |
| `give @s diamond 64` | a stack of diamonds |
| `give Alice netherite_sword` | count defaults to 1 |
| `give @a golden_apple 8` | 8 to every player |
| `clear Alice` | empty entire inventory |
| `clear @s dirt` | remove all dirt only |

Pre-enchanted gear uses the component syntax (1.20.5+):

```text
give @s diamond_sword[enchantments={sharpness:5,unbreaking:3}]
```

For ≤ 1.20.4 use NBT instead:

```text
give @s diamond_sword{Enchantments:[{id:sharpness,lvl:5}]}
```

## Enchanting & effects

| Command | Effect |
| --- | --- |
| `enchant @s sharpness 5` | enchant held item |
| `effect give @s speed 120 2` | seconds, amplifier (= level 3) |
| `effect give @s night_vision infinite` | permanent until cleared |
| `effect clear @s` | remove all effects |

- `enchant` respects normal enchantment limits (level caps, item
  compatibility) — for over-the-top gear use `give` with components.
- Effect amplifier is **zero-based**: amplifier 2 = level III.

## Experience

| Command | Effect |
| --- | --- |
| `xp add @s 30 levels` | also: `points` |
| `xp set Alice 0 points` | zero out partial bar |
| `xp query @s levels` | check current level |
