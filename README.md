# RodrigoDKi Craft Ops

**Site: <https://rdlu.github.io/mc-cheatsheet/>** — rebuilt on every push by
GitHub Actions (`.github/workflows/docs.yml`, same `mise run site` as local).

Minecraft tips & server-management docs site, plus a two-page PDF
cheatsheet: common server commands (teleport, give, gamerules,
moderation, …) aimed at use over RCON (`mcrcon -t`) or the server console —
written without the leading `/` — and survival tips (early game, farms,
enchanting, nether, villagers). Targets vanilla **26.1** (verified against
a live 26.1.2 server; pre-26 differences are footnoted where they matter —
camelCase gamerules, `time query daytime`).

- Markdown sources in `docs/`, built into `site/` by
  [Zensical](https://zensical.org) (via `uvx`, nothing installed)
- PDF cheatsheet from `cheatsheet.typ` ([Typst](https://typst.app)),
  Catppuccin **Latte** (print) + **Mocha** (screens) variants in `docs/pdf/`
- `bin/mc-tui` — the cheatsheet as an interactive fzf TUI: browse the
  commands, fill `<player>`/`<item>`/… placeholders from pickers, then
  copy to the clipboard or run over RCON (settings + saved player names
  in `~/.config/mc-tui/`). Also opens the world on chunkbase from the
  live seed + player position (`[map]` / `mc-tui map [player]`), or a
  **live follow map** that re-centers a Chromium tab on a player every
  few seconds (`mise run follow` to pick from who's online and set the
  interval, or `mc-tui follow <player> [secs]` directly, via
  `scripts/follow-map.py` over the DevTools protocol)
- [Command builder](https://rdlu.github.io/mc-cheatsheet/builder/) — the
  same picker as a web page (phone-friendly, EN/pt-BR searchable, copy
  to paste in-game); its data is generated from the mc-tui tables by
  `scripts/builder-data.py` at build time
- Tools and tasks managed with [mise](https://mise.jdx.dev)

## Build

```sh
mise install      # typst + uv (pinned in mise.toml)
mise run setup    # one-time system deps: fonts + mcrcon (paru/AUR)

mise run serve    # live-preview the site at localhost:8000
mise run site     # full build: PDFs + HTML into site/
mise run pdf      # just the cheatsheet PDFs into docs/pdf/
mise run watch    # live-rebuild the PDF while editing (THEME=mocha for dark)
mise run open     # build and open site/index.html
mise run tui      # mc-tui: pick a command, fill it in, copy or run over RCON
mise run console  # interactive RCON console (nmcrcon/mcrcon) with saved settings
mise run session  # tmux session: mc-tui + RCON console side by side
                  # (`mise run session zellij` for zellij instead)
```

## Notes

- The pre-enchanted `give` example uses the component syntax introduced in
  1.20.5; for ≤ 1.20.4 use NBT
  (`give @s diamond_sword{Enchantments:[{id:sharpness,lvl:5}]}`).
- Edit `cheatsheet.typ` to add sections — each is a
  `#section("Title")[#cmds(...)]` block with `[command], [description]`
  pairs (`wide[...]` spans both columns). Section colors cycle through the
  Catppuccin accents automatically.
