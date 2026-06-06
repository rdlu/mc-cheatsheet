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

!!! note "1.21.0 – 1.21.4"
    The flattened `enchantments={sharpness:5}` form is 1.21.5+; earlier
    1.21 releases use `enchantments={levels:{sharpness:5}}`.

## Useful items

Item IDs worth knowing for `give` — gear sets combine a material prefix
(`netherite_`, `diamond_`, `iron_`, `golden_`, `stone_`, `wooden_`,
plus `leather_`/`chainmail_` for armor) with the piece:

| Category | Items |
| --- | --- |
| Gear sets | `sword` `pickaxe` `axe` `shovel` `hoe` · `helmet` `chestplate` `leggings` `boots` |
| Ranged | `bow` · `crossbow` · `arrow 64` · `trident` · `mace` |
| Survival | `shield` · `totem_of_undying` · `golden_apple` · `enchanted_golden_apple` · `cooked_beef 64` · `golden_carrot 64` |
| Mobility | `elytra` · `firework_rocket 64` · `ender_pearl 16` · `saddle` |
| Utility | `water_bucket` · `lava_bucket` · `flint_and_steel` · `torch 64` · `name_tag` · `lead` · `compass` · `recovery_compass` · `spyglass` · `experience_bottle 64` |
| Storage | `shulker_box` · `ender_chest` · `bundle` |

## God gear

Fully-enchanted kit, one command per piece (component syntax):

```text
give @s netherite_sword[enchantments={sharpness:5,looting:3,sweeping_edge:3,fire_aspect:2,unbreaking:3,mending:1}]
give @s netherite_pickaxe[enchantments={efficiency:5,fortune:3,unbreaking:3,mending:1}]
give @s netherite_axe[enchantments={efficiency:5,sharpness:5,unbreaking:3,mending:1}]
give @s netherite_helmet[enchantments={protection:4,respiration:3,aqua_affinity:1,unbreaking:3,mending:1}]
give @s netherite_chestplate[enchantments={protection:4,unbreaking:3,mending:1}]
give @s netherite_leggings[enchantments={protection:4,unbreaking:3,mending:1}]
give @s netherite_boots[enchantments={protection:4,feather_falling:4,depth_strider:3,unbreaking:3,mending:1}]
give @s bow[enchantments={power:5,infinity:1,unbreaking:3}]
give @s trident[enchantments={loyalty:3,channeling:1,impaling:5,unbreaking:3,mending:1}]
give @s elytra[enchantments={unbreaking:3,mending:1}]
```

- Swap `fortune:3` for `silk_touch:1` on a second pickaxe.
- Mending + Infinity don't combine on bows — pick one.
- Mace enchants: `density:5` or `breach:4` (exclusive), plus `wind_burst:3`.
- **Diamond instead of netherite?** Just swap the `netherite_` prefix for
  `diamond_` — the enchantments are identical. Diamond is the early/mid-game
  pick (no ancient-debris grind); netherite is actually *more* durable (e.g.
  2031 vs 1561 uses on tools) and survives lava — but with Unbreaking III +
  Mending, both effectively never wear out.

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
