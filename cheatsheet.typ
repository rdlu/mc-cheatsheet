// Minecraft cheatsheet — page 1: server commands, page 2: survival tips.
// Themed with Catppuccin.
//
// Compile (see `mise run pdf`):
//   typst compile --input theme=latte cheatsheet.typ docs/pdf/mc-cheatsheet.pdf
//   typst compile --input theme=mocha cheatsheet.typ docs/pdf/mc-cheatsheet-mocha.pdf

#let theme-id = sys.inputs.at("theme", default: "latte")

// Catppuccin Latte (light, print-friendly) and Mocha (dark, screens).
#let themes = (
  latte: (
    bg: rgb("#eff1f5"), text: rgb("#4c4f69"), subtext: rgb("#6c6f85"),
    card: rgb("#e6e9ef"), code: rgb("#1e66f5"), title-text: rgb("#eff1f5"),
    accents: (rgb("#40a02b"), rgb("#1e66f5"), rgb("#8839ef"), rgb("#fe640b"),
              rgb("#d20f39"), rgb("#179299"), rgb("#df8e1d"), rgb("#ea76cb")),
  ),
  mocha: (
    bg: rgb("#1e1e2e"), text: rgb("#cdd6f4"), subtext: rgb("#a6adc8"),
    card: rgb("#181825"), code: rgb("#89b4fa"), title-text: rgb("#11111b"),
    accents: (rgb("#a6e3a1"), rgb("#89b4fa"), rgb("#cba6f7"), rgb("#fab387"),
              rgb("#f38ba8"), rgb("#94e2d5"), rgb("#f9e2af"), rgb("#f5c2e7")),
  ),
)
#let pal = themes.at(theme-id)

// Per-page header: commands on page 1, tips on page 2.
#let headers = (
  ([Minecraft Server Commands],
   [for RCON / server console — no leading `/` needed · vanilla 26.1]),
  ([Minecraft Survival Tips],
   [early game · farms · enchanting · nether · villagers]),
)
#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 0.8cm, top: 1.2cm, bottom: 0.8cm),
  fill: pal.bg,
  columns: 3,
  header: context {
    let (title, sub) = headers.at(
      calc.min(counter(page).get().first(), headers.len()) - 1)
    grid(
      columns: (auto, 1fr),
      align: (left + bottom, right + bottom),
      text(size: 14pt, weight: "black", fill: pal.text,
        title + h(4pt) +
        text(size: 9pt, weight: "regular", fill: pal.subtext, "cheatsheet")),
      text(size: 7.5pt, fill: pal.subtext, sub),
    )
  },
  footer: align(center, text(size: 6.5pt, fill: pal.subtext,
    [RodrigoDKi Craft Ops · generated #datetime.today().display() ·
      page #context counter(page).display("1 / 1", both: true)])),
)
#set columns(gutter: 16pt)
#set text(size: 7.2pt, font: "Inter", fill: pal.text)
#set par(leading: 0.4em)
#set list(indent: 0pt, body-indent: 3pt, spacing: 3pt, marker: text(fill: pal.subtext, sym.bullet))
#set enum(indent: 0pt, body-indent: 3pt, spacing: 3pt, numbering: n => text(fill: pal.subtext, weight: "bold", str(n) + "."))
#show raw: set text(font: "JetBrains Mono", size: 0.93em, fill: pal.code)

// Sections cycle through the Catppuccin accents.
#let section-count = counter("section")
#let section(title, body) = block(breakable: false, below: 7pt)[
  #section-count.step()
  #context {
    let i = section-count.get().first()
    let accent = pal.accents.at(calc.rem(i - 1, pal.accents.len()))
    block(
      fill: accent, width: 100%, radius: 2pt, inset: (x: 5pt, y: 3.2pt),
      text(fill: pal.title-text, weight: "bold", size: 1.06em, upper(title)),
    )
  }
  #body
]

#let cmds(..rows) = table(
  columns: (auto, 1fr),
  stroke: none,
  fill: (x, y) => if calc.odd(y) { pal.card },
  inset: (x: 3pt, y: 2.2pt),
  ..rows,
)

// one full-width row (for long commands)
#let wide(body) = table.cell(colspan: 2, body)

// prose body for the tips page (page 2)
#let tips(body) = block(inset: (x: 3pt, y: 2pt), body)

#section("Target selectors")[
  #cmds(
    [`@p`], [nearest player],
    [`@a`], [all players],
    [`@r`], [random player],
    [`@e`], [all entities],
    [`@s`], [the command's executor (yourself)],
    wide[`@e[type=zombie,distance=..10,limit=3,sort=nearest]`],
    wide[`@a[gamemode=survival]` · `@e[type=item]` — filters combine with `,`],
  )
]

#section("Coordinates")[
  #cmds(
    [`100 64 -200`], [absolute X Y Z],
    [`~ ~ ~`], [relative to executor (`~5` = +5)],
    [`~ ~10 ~`], [10 blocks above current spot],
    [`^ ^ ^5`], [local: 5 blocks in facing direction],
  )
]

#section("Teleporting")[
  #cmds(
    [`tp Alice Bob`], [Alice → Bob],
    [`tp @s 100 64 -200`], [yourself → coords],
    [`tp @s ~ ~20 ~`], [20 blocks straight up],
    [`tp @a @s`], [everyone → you],
    [`tp @s 0 64 0 90 0`], [with facing (yaw pitch)],
    [`spawnpoint @s ~ ~ ~`], [set respawn point here],
    [`setworldspawn 0 64 0`], [set world spawn],
  )
]

#section("Giving items")[
  #cmds(
    [`give @s diamond 64`], [a stack of diamonds],
    [`give Alice netherite_sword`], [count defaults to 1],
    [`give @a golden_apple 8`], [8 to every player],
    wide[`give @s diamond_sword[enchantments={sharpness:5,unbreaking:3}]` — pre-enchanted (1.20.5+)],
    [`clear Alice`], [empty entire inventory],
    [`clear @s dirt`], [remove all dirt only],
  )
]

#section("Useful items to give")[
  #cmds(
    [*Gear sets*], [`netherite_`/`diamond_`/`iron_` + `sword` `pickaxe` `axe` `shovel` `hoe` `helmet` `chestplate` `leggings` `boots`],
    [*Ranged*], [`bow` · `crossbow` · `arrow 64` · `trident` · `mace`],
    [*Survival*], [`shield` · `totem_of_undying` · `golden_apple` · `enchanted_golden_apple` · `cooked_beef 64` · `golden_carrot 64`],
    [*Mobility*], [`elytra` · `firework_rocket 64` · `ender_pearl 16` · `saddle`],
    [*Utility*], [`water_bucket` · `lava_bucket` · `flint_and_steel` · `torch 64` · `name_tag` · `lead` · `recovery_compass` · `spyglass` · `experience_bottle 64`],
    [*Storage*], [`shulker_box` · `ender_chest` · `bundle`],
    wide[god pickaxe: `give @s netherite_pickaxe[enchantments={efficiency:5,fortune:3,unbreaking:3,mending:1}]`],
  )
]

#section("Enchant · effects · XP")[
  #cmds(
    [`enchant @s sharpness 5`], [enchant held item],
    [`effect give @s speed 120 2`], [seconds, amplifier (= level 3)],
    [`effect give @s night_vision infinite`], [],
    [`effect clear @s`], [remove all effects],
    [`xp add @s 30 levels`], [also: `points`],
    [`xp set Alice 0 points`], [`xp query @s levels`],
  )
]

#section("Game mode & difficulty")[
  #cmds(
    [`gamemode creative`], [also: `survival`, `adventure`, `spectator`],
    [`gamemode survival Alice`], [for another player],
    [`defaultgamemode survival`], [for new players],
    [`difficulty hard`], [`peaceful` `easy` `normal` `hard`],
  )
]

#section("Time & weather")[
  #cmds(
    [`time set day`], [also: `noon`, `night`, `midnight`],
    [`time set 1000`], [ticks (24000 = full day)],
    [`time query time`], [current clock ticks],
    [`time pause` / `time resume`], [freeze / unfreeze the clock],
    [`weather clear`], [also: `rain`, `thunder`],
    [`weather rain 600`], [duration in seconds],
  )
]

#section("Useful gamerules")[
  #cmds(
    [`gamerule keep_inventory true`], [no item loss on death],
    [`gamerule mob_griefing false`], [no creeper/enderman damage],
    [`gamerule advance_time false`], [freeze time],
    [`gamerule advance_weather false`], [freeze weather],
    [`gamerule spawn_mobs false`], [no hostile spawns],
    [`gamerule players_sleeping_percentage 1`], [one sleeper skips night],
    [`gamerule random_tick_speed 3`], [crop growth speed (default 3)],
    wide[pre-26 names were camelCase: `keepInventory`, `doDaylightCycle`, …],
  )
]

#section("Building")[
  #cmds(
    [`setblock ~ ~ ~ stone`], [place one block],
    [`fill 0 64 0 10 70 10 glass`], [fill region (max 32 768 blocks)],
    [`fill 0 64 0 10 70 10 air`], [clear a region],
    wide[`fill 0 64 0 10 70 10 stone replace dirt` — replace only dirt],
    wide[`clone 0 64 0 10 70 10 50 64 50` — copy region to new corner],
  )
]

#section("Entities & world")[
  #cmds(
    [`summon zombie ~ ~ ~`], [spawn an entity],
    [`summon lightning_bolt`], [smite current spot],
    [`kill @e[type=item]`], [clear dropped items (lag)],
    [`kill @e[type=zombie,distance=..20]`], [nearby zombies],
    [`locate structure village_plains`], [coords of nearest],
    [`locate biome cherry_grove`], [nearest biome],
    [`seed`], [show world seed],
  )
]

#section("Chat & players")[
  #cmds(
    [`list`], [who's online (great over RCON)],
    [`say Server restarting soon`], [broadcast to all],
    [`msg Alice dinner time`], [private message],
    wide[`tellraw @a {"text":"Hello","color":"gold","bold":true}` — formatted broadcast],
    [`kick Alice afk too long`], [reason is optional],
  )
]

#section("Moderation")[
  #cmds(
    [`op Alice` / `deop Alice`], [grant / revoke operator],
    [`whitelist add Alice`], [also: `remove`, `list`, `reload`],
    [`whitelist on`], [enforce the whitelist],
    [`ban Alice griefing`], [`pardon Alice` to undo],
    [`ban-ip 1.2.3.4`], [`pardon-ip` to undo],
    [`banlist`], [show bans],
  )
]

#section("Server maintenance (RCON favorites)")[
  #cmds(
    [`save-all`], [flush world to disk],
    [`save-off` / `save-on`], [pause autosave (do this around backups)],
    [`stop`], [graceful shutdown],
    [`help` / `help tp`], [list commands / usage of one],
  )
]

// ──────────────────────────── page 2: survival tips ─────────────────────────
// Prose needs fewer rows than command tables — scale up so the page fills.
#pagebreak()
#section-count.update(0)
#set text(size: 8.4pt)
#set list(spacing: 3.6pt)
#set enum(spacing: 3.6pt)

#section("Early game — day one")[
  #tips[
    + *Punch trees* (\~10 logs) → crafting table + wooden pickaxe
    + 3 cobblestone → *stone pickaxe*, then stone axe/sword/shovel — skip
      making more wooden tools
    + *Cook your meat* — raw food is a trap; break tall grass for wheat seeds
    + *Bed*: 3 wool + 3 planks — skips the night _and_ sets your respawn
    + *Shelter*: dig into a hillside and plug the hole; a door beats an
      ambitious half-finished house at sundown
  ]
]

#section("First mining trip")[
  #tips[
    - *Staircase down* — never dig straight down (gravel, caves, lava)
    - Bring food, torches, spare wood; a *water bucket* as soon as you have iron
    - \~32 iron ore = full armor + tools, smelted with coal mined on the way
    - Diamonds are best at *Y −58/−59* (1.18+); lava lakes start around Y −54 —
      bring the water bucket before going that deep
    - Torches *on the right wall* going in — right-hand rule leads home
  ]
]

#section("Early essentials")[
  #tips[
    - Full iron armor + *shield* — blocks creeper blasts and skeleton arrows
    - Crop farm: 9×9 plot, water in the center hydrates all of it
    - Small cow/sheep pen — wheat lures them, breed pairs
    - Sugar cane on a water edge → paper for bookshelves later
    - A *bucket on the hotbar* saves you from lava, falls, and creepers
    - Items despawn *5 min* after death — carry less until routes are safe
  ]
]

#section("Farms, in order")[
  #tips[
    + *Crops* — wheat + carrots + potatoes; composter eats the excess → bone meal
    + *Sugar cane* — only the bottom block must stay; observer-piston later
    + *Bamboo/cactus* — grow unattended; bamboo doubles as furnace-XP afk fuel
    + *Mob XP farm* — dark room or dungeon spawner, water stream to a
      one-hit kill chamber
    + *Iron farm* — 3+ villagers + beds + a zombie scare → golems; trivializes
      hoppers, rails, buckets, anvils
  ]
]

#section("Mob farm notes")[
  #tips[
    - Hostiles spawn at *light level 0* only (1.18+) — any light spawn-proofs
    - Farms work when players are *24–128 blocks* from the spawning spaces
    - `gamerule mobGriefing false` breaks creeper/wither-based designs
  ]
]

#section("Enchanting setup")[
  #tips[
    - *15 bookshelves* (1-block gap around the table) unlock level-30 enchants —
      3 leather + 9 paper each
    - A level-30 enchant costs *3 levels + 3 lapis*, not 30 levels — enchant
      early and often once past level 30
    - Don't enchant or repair iron gear — it's disposable; save levels for diamond
  ]
]

#section("Enchant priorities")[
  #cmds(
    [*Pickaxe*], [Efficiency, Unbreaking → Fortune III (or Silk Touch on a 2nd pick)],
    [*Sword*], [Sharpness → Looting III, Sweeping Edge],
    [*Armor*], [Protection IV → Feather Falling IV (boots), Respiration (helmet)],
    [*Everything*], [*Mending* — from fishing, trading, or chest loot only],
  )
]

#section("Anvil notes")[
  #tips[
    - Combining identical items merges enchants, but the *prior-work penalty
      doubles* each combine — plan the tree, don't chain endlessly
    - "Too expensive!" caps at *40 levels*
    - A grindstone strips enchants and refunds a little XP
    - Mending and Infinity are mutually exclusive on bows
  ]
]

#section("Nether portals")[
  #tips[
    - 1 nether block = *8 overworld blocks* — build hub tunnels nether-side
    - To link deliberately: overworld X/Z *÷ 8*, build the nether portal there;
      portals link to the _nearest existing_ portal
    - A frame needs only *10 obsidian* (corners optional) — a water bucket on a
      lava lake casts one with no diamond pickaxe
  ]
]

#section("Nether survival")[
  #tips[
    - *Fire Resistance potions* (nether wart + magma cream) make it casual
    - Carry flint & steel — ghasts blow out portals
    - Never sleep: *beds explode* in the nether (respawn anchors work)
    - Wearing *any gold armor piece* keeps piglins neutral; hoglins fear
      warped fungus
  ]
]

#section("Fast travel")[
  #tips[
    - *Blue-ice boat highways*: \~40–70 blocks/s — 2-wide lane + slab roof
      against ghasts
    - Elytra + rockets is endgame travel; until then, nether hubs beat
      overworld roads
  ]
]

#section("Villagers")[
  #tips[
    - A villager needs a *bed* + a *job block* (lectern → librarian,
      blast furnace → armorer, grindstone → weaponsmith)
    - *Reroll librarians*: break/replace the lectern until the book you want
      (e.g. Mending) appears — the trade locks once you trade
    - Breed: *3 bread or 12 carrots/potatoes* per villager + spare beds
    - *Cure* a zombified villager (weakness splash + golden apple) for
      near-permanent massive discounts
  ]
]

#section("Starter trades")[
  #cmds(
    [*Farmer*], [crops → emeralds (easy emerald engine)],
    [*Fletcher*], [sticks → emeralds (cheapest trade in the game)],
    [*Librarian*], [Mending, Efficiency, Protection books],
    [*Smiths*], [diamond gear for emeralds],
    [*Cleric*], [rotten flesh → emeralds; ender pearls],
  )
]
