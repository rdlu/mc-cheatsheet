# RodrigoDKi Craft Ops

Minecraft tips and server management notes — vanilla **26.1**
(pre-26 differences footnoted), run over RCON with
[`mcrcon`](https://github.com/Tiiffi/mcrcon) (commands written
without the leading `/`).

## Contents

- **[Command builder](builder.md)** — interactive picker: choose a command,
  fill in the blanks (items searchable in English or **pt-BR**), copy,
  paste in-game — works on phones, great for sharing with friends
- **[Commands](commands/selectors.md)** — the cheatsheet as browsable pages:
  [selectors & coordinates](commands/selectors.md),
  [teleporting](commands/teleport.md),
  [items, enchants & XP](commands/items.md),
  [world control](commands/world.md),
  [chat & moderation](commands/moderation.md),
  [server maintenance](commands/maintenance.md)
- **[Tips](tips/early-game.md)** — gameplay notes:
  [early game](tips/early-game.md),
  [farms](tips/farms.md),
  [enchanting](tips/enchanting.md),
  [nether & travel](tips/nether.md),
  [villagers](tips/villagers.md)
- **[Server management](server.md)** — mcrcon usage, RCON setup, backup flow

## PDF downloads

Two-page landscape cheatsheet (A4, Catppuccin — **Latte** for print,
**Mocha** for screens), built from `cheatsheet.typ` with `mise run pdf`:

<div class="pdf-grid">
  <div class="pdf-card commands wide">
    <span class="pdf-title"><span class="pdf-icon">⛏️</span> Minecraft cheatsheet</span>
    <span class="pdf-sub">page 1: server commands, selectors to RCON maintenance · page 2: survival tips · vanilla 26.1</span>
    <span class="pdf-links">
      <a href="pdf/mc-cheatsheet.pdf">Latte</a>
      <a href="pdf/mc-cheatsheet-mocha.pdf">Mocha</a>
    </span>
  </div>
</div>

## How this site works

Markdown sources live in `docs/`; [Zensical](https://zensical.org) builds the
HTML site into `site/` via `uvx` (nothing installed). The PDF cheatsheet is a
[Typst](https://typst.app) source compiled into `docs/pdf/` so the site can
link it. Tools and tasks are managed with [mise](https://mise.jdx.dev):
`mise run serve` to preview, `mise run site` for a full build.
