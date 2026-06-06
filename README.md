# RodrigoDKi Craft Ops — Minecraft commands cheatsheet, RCON TUI & server-admin guide

A practical toolkit for running a **Minecraft** server: a browsable **command
cheatsheet** (teleport, `give`, gamerules, moderation, …), survival **tips**,
a printable **PDF**, and **`mc-tui`** — an interactive terminal app that builds
commands for you and sends them over **RCON**. Targets vanilla **26.1**
(verified against a live Fabric server; pre-26 differences are footnoted).

**📖 Read it online: <https://rdlu.github.io/mc-cheatsheet/>**
&nbsp;·&nbsp; **🧩 Web command builder: <https://rdlu.github.io/mc-cheatsheet/builder/>**

All commands are written **without the leading `/`**, the way the server
console and RCON expect them — copy, paste, run.

![mc-tui — browse a command, fill the blanks (searchable in English or pt-BR), copy or run over RCON](docs/img/mc-tui.gif)

---

## What's inside

| | |
| --- | --- |
| 🌐 **Docs site** | Browsable [command pages](https://rdlu.github.io/mc-cheatsheet/commands/selectors/) and [survival tips](https://rdlu.github.io/mc-cheatsheet/tips/early-game/) (early game, farms, enchanting, nether, villagers) — built with [Zensical](https://zensical.org). |
| 🖨️ **PDF cheatsheet** | A two-page landscape A4 sheet ([Typst](https://typst.app)), Catppuccin **Latte** for print + **Mocha** for screens. Page 1 = server commands, page 2 = survival tips. |
| ⌨️ **`mc-tui`** | An [fzf](https://github.com/junegunn/fzf) terminal app: pick a command, fill the blanks from smart pickers, then **copy** it or **run it over RCON**. Plus a chunkbase seed-map opener and a **live follow map**. |
| 🧩 **Web command builder** | The same picker as a phone-friendly web page — no install, searchable in **English or Brazilian Portuguese (pt-BR)**. |

---

## `mc-tui` — the cheatsheet as a terminal app

```sh
mise run tui
```

[`bin/mc-tui`](bin/mc-tui) (fish + fzf) wraps the whole cheatsheet in an
interactive picker:

- **Browse 100+ commands** across 12 categories, including a full god-gear set
  with the modern component enchantment syntax.
- **Placeholders are filled interactively** — `<player>` offers your saved
  names and selectors, `<item>` searches ~215 useful items (gear, food,
  potions, enchanted books, redstone, blocks…), and `<enchantment>`,
  `<effect>`, `<entity>`, `<structure>`, `<biome>` each get their own picker.
- **Bilingual search (EN + pt-BR)** — item/enchant/effect/entity/biome pickers
  carry the **official** Brazilian Portuguese names from the game's language
  file, so `picareta`, `fogueira` or `remendo` find the right id.
- **Copy or run** — send the finished command to the clipboard, or straight to
  the server over RCON with [`mcrcon`](https://github.com/Tiiffi/mcrcon).
- **`[console]`** — an interactive RCON session, preferring
  [`nmcrcon`](https://github.com/nicholascw/nmcrcon) (line editing, history,
  multi-packet responses) and falling back to `mcrcon -t`.
- **`[players]`** — saved names for `<player>` slots; `ctrl-f` grabs whoever's
  online right now via `list`.
- **`[map]`** — open the world on [chunkbase](https://www.chunkbase.com/apps/seed-map)
  from the live seed, centered on spawn, coordinates, or a player's position.
- **`[settings]`** — RCON host / port / password, chunkbase platform tag, and
  follow-map interval/zoom, stored in `~/.config/mc-tui/rcon.conf` (`chmod 600`).

### Live follow map 🛰️

```sh
mise run follow                  # pick from who's online, choose the interval
mise run follow Steve 5          # follow Steve, refresh every 5s
```

Opens chunkbase in a dedicated Chromium window and **re-centers it on the
player every few seconds** so you can watch them move in real time. Driven by
[`scripts/follow-map.py`](scripts/follow-map.py) over the Chrome DevTools
Protocol; your zoom is preserved as you scroll, and it follows the player
between the overworld, nether, and end.

### Subcommands

| Command | What it does |
| --- | --- |
| `mc-tui` | the interactive TUI |
| `mc-tui console` | interactive RCON session (saved settings) |
| `mc-tui run <cmd…>` | one-shot command — handy in scripts and backups |
| `mc-tui map [player]` | open the world on chunkbase |
| `mc-tui follow [player] [secs]` | live follow map |
| `mc-tui session [tmux\|zellij]` | TUI + RCON console side by side |

The command and item tables are plain pipe-delimited text — inspect them with
`mc-tui __dump catalog` (or `items`, `enchantments`, …) and extend them in
`~/.config/mc-tui/catalog.local` / `items.local`.

> [!WARNING]
> **RCON is plaintext.** It sends the password and every command unencrypted —
> only use it on `localhost`, a trusted LAN, or through an SSH tunnel
> (`ssh -L 25575:localhost:25575 host`). Never expose `rcon.port` to the
> internet.

---

## Install & build

Tools and tasks are managed with [mise](https://mise.jdx.dev).

```sh
mise install      # pinned tools: typst + uv
mise run setup    # system deps (Arch/paru): fonts, mcrcon, nmcrcon, fzf,
                  # wl-clipboard, chromium
```

### Tasks

```sh
# docs site + PDF
mise run serve    # live-preview the site at localhost:8000
mise run site     # full build: PDFs + HTML into site/
mise run pdf      # just the cheatsheet PDFs (docs/pdf/)
mise run watch    # live-rebuild the PDF while editing (THEME=mocha for dark)
mise run open     # build and open the site

# server tools
mise run tui      # mc-tui: pick a command, fill it in, copy or run over RCON
mise run console  # interactive RCON console with saved settings
mise run session  # tmux/zellij: mc-tui + RCON console side by side
mise run follow   # live follow map on chunkbase
```

The docs site rebuilds and deploys to GitHub Pages on every push to `main`
(`.github/workflows/docs.yml`, running the same `mise run site`).

## Project layout

```
cheatsheet.typ          Typst source for the two-page PDF (Catppuccin themed)
bin/mc-tui              the fish + fzf terminal app (RCON, pickers, maps)
scripts/follow-map.py   chromium + CDP driver for the live follow map
scripts/builder-data.py generates the web builder's data from the mc-tui tables
docs/                   Markdown sources for the site (commands, tips, server)
zensical.toml           site config; mise.toml  tools + tasks
```

## Notes

- Built for vanilla **26.1** and verified over RCON against a live 26.1.2
  Fabric server. Pre-26 differences (camelCase gamerules like `keepInventory`,
  `time query daytime`) are footnoted in the docs.
- Pre-enchanted `give` uses the 1.20.5+ component syntax
  (`give @s diamond_sword[enchantments={sharpness:5}]`); for ≤ 1.20.4 use NBT.
- Edit `cheatsheet.typ` to add PDF sections — each is a
  `#section("Title")[#cmds(...)]` block; section colors cycle through the
  Catppuccin accents automatically.

## Credits

Cheatsheet content & tooling by Rodrigo Dlugokenski. Built on
[Zensical](https://zensical.org), [Typst](https://typst.app),
[mise](https://mise.jdx.dev), [fzf](https://github.com/junegunn/fzf),
[mcrcon](https://github.com/Tiiffi/mcrcon) /
[nmcrcon](https://github.com/nicholascw/nmcrcon), and
[chunkbase](https://www.chunkbase.com). Themed with
[Catppuccin](https://catppuccin.com). Português (pt-BR) item names come from
Mojang's official game language files.
