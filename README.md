# RodrigoDKi Craft Ops

**Site: <https://rdlu.github.io/mc-cheatsheet/>** — rebuilt on every push by
GitHub Actions (`.github/workflows/docs.yml`, same `mise run site` as local).

Minecraft tips & server-management docs site, plus a two-page PDF
cheatsheet: common server commands (teleport, give, gamerules,
moderation, …) aimed at use over RCON (`mcrcon -t`) or the server console —
written without the leading `/` — and survival tips (early game, farms,
enchanting, nether, villagers). Targets vanilla **1.21.x**.

- Markdown sources in `docs/`, built into `site/` by
  [Zensical](https://zensical.org) (via `uvx`, nothing installed)
- PDF cheatsheet from `cheatsheet.typ` ([Typst](https://typst.app)),
  Catppuccin **Latte** (print) + **Mocha** (screens) variants in `docs/pdf/`
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
```

## Notes

- The pre-enchanted `give` example uses the component syntax introduced in
  1.20.5; for ≤ 1.20.4 use NBT
  (`give @s diamond_sword{Enchantments:[{id:sharpness,lvl:5}]}`).
- Edit `cheatsheet.typ` to add sections — each is a
  `#section("Title")[#cmds(...)]` block with `[command], [description]`
  pairs (`wide[...]` spans both columns). Section colors cycle through the
  Catppuccin accents automatically.
