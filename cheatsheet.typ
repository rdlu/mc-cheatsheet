// Minecraft server command cheatsheet, themed with Catppuccin.
//
// Compile (see `just pdf`):
//   typst compile --input theme=latte cheatsheet.typ docs/pdf/mc-commands-cheatsheet.pdf
//   typst compile --input theme=mocha cheatsheet.typ docs/pdf/mc-commands-cheatsheet-mocha.pdf

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

#set page(
  paper: "a4",
  flipped: true,
  margin: (x: 0.8cm, top: 1.2cm, bottom: 0.8cm),
  fill: pal.bg,
  columns: 3,
  header: grid(
    columns: (auto, 1fr),
    align: (left + bottom, right + bottom),
    text(size: 14pt, weight: "black", fill: pal.text,
      [Minecraft Server Commands] + h(4pt) +
      text(size: 9pt, weight: "regular", fill: pal.subtext, "cheatsheet")),
    text(size: 7.5pt, fill: pal.subtext,
      [for RCON / server console — no leading `/` needed · vanilla 1.21.x]),
  ),
  footer: align(center, text(size: 6.5pt, fill: pal.subtext,
    [RodrigoDKi Craft Ops · generated #datetime.today().display()])),
)
#set columns(gutter: 16pt)
#set text(size: 7.2pt, font: "Inter", fill: pal.text)
#set par(leading: 0.4em)
#show raw: set text(font: "JetBrains Mono", size: 6.7pt, fill: pal.code)

// Sections cycle through the Catppuccin accents.
#let section-count = counter("section")
#let section(title, body) = block(breakable: false, below: 7pt)[
  #section-count.step()
  #context {
    let i = section-count.get().first()
    let accent = pal.accents.at(calc.rem(i - 1, pal.accents.len()))
    block(
      fill: accent, width: 100%, radius: 2pt, inset: (x: 5pt, y: 3.2pt),
      text(fill: pal.title-text, weight: "bold", size: 7.6pt, upper(title)),
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
    [`time add 1000`], [advance time],
    [`time query daytime`], [current time of day],
    [`weather clear`], [also: `rain`, `thunder`],
    [`weather rain 600`], [duration in seconds],
  )
]

#section("Useful gamerules")[
  #cmds(
    [`gamerule keepInventory true`], [no item loss on death],
    [`gamerule mobGriefing false`], [no creeper/enderman damage],
    [`gamerule doDaylightCycle false`], [freeze time],
    [`gamerule doWeatherCycle false`], [freeze weather],
    [`gamerule doMobSpawning false`], [no hostile spawns],
    [`gamerule playersSleepingPercentage 1`], [one sleeper skips night],
    [`gamerule randomTickSpeed 3`], [crop growth speed (default 3)],
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
    [`locate structure village`], [coords of nearest],
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
