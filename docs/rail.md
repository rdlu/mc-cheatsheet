# Railroad builder

Build **surface and air railroads** straight from where your character is
standing — always-powered lines and stations — without placing a single block by
hand. `mc-tui` reads your position and facing over RCON, compiles the track to
`fill`/`setblock` commands, and streams them to the server.

Lines are authored as small **YAML** files, so they're portable, versionable and
re-runnable. All commands are sent over RCON (no datapack or world-file access
needed), which suits a remote server.

![rail builder](img/mc-tui.gif)

## Quick start

```sh
mc-tui            # then choose  [rail builder]  →  build a line
```

Stand where the line should start, look the way it should go, and the wizard
walks you through it:

1. **player** — whose position/facing to use
2. **direction** — defaults to the way you're facing (override if you like)
3. **height offset** — `0` = at your feet, or raise it for a sky bridge
4. **width** — `3` (a platform with walkable edges) or `1` (just the rail)
5. **length** — `16 / 32 / 64 / 128 / 256`, or type any number
6. **deck** — the polished/brick stone palette (or type any block)
7. **line color** — a subway-style stripe under the rail (or none)
8. **walls** — `none`, glass, fences, brick walls…
9. **lighting** — lamp posts or edge lanterns (see below)

You get a **preview** of the commands, then **run over RCON**, **copy** them, or
**save as YAML** to `~/.config/mc-tui/rail/`.

## Always powered

Every rail is a `powered_rail`, kept energised by a `redstone_block` tucked into
the deck under the rail every **9 blocks**. An energised powered rail relays
power up to 8 rails each way, and 9-block spacing (placed start-to-end) lands
each new source on a still-unpowered rail so it relays cleanly — no dead "brake"
segments, constant top speed. Just drop a minecart and ride.

## Lighting

Any block light stops hostile mob spawns, so a lit line can't become a mob
conveyor. Two styles, placed every `light_spacing` (default 8 — ≤ 24 keeps the
whole track spawn-proof):

- **poles** — a lamp post just beyond the deck edge with a lantern on top
- **edge** — lanterns sitting on top of the deck edge
- **sides of base** — lanterns hanging under the deck edge (full blocks like
  sea lanterns sit flush on the flank)

Pick any light block (lantern, sea lantern, glowstone, end rod…) and which
side(s) to light.

## Stations

`[rail builder]` → **place a station** drops a stop at your position, oriented
to your facing:

- **halt** — an open platform with a lever-controlled launcher and corner
  lanterns
- **covered** — the same, plus a roof, pillars and hanging lanterns

The middle of the station is a `powered_rail` that's **unpowered by default** (a
brake), isolated from the line's power by short regular-rail sections — so an
arriving cart **stops**. Flip the **lever** beside it to energise the launcher
and the cart departs; flip it off to park.

You can also add stations to a line's YAML directly:

```yaml
stations:
  - { at: start, type: covered }
  - { at: 64,    type: halt }      # at: start | end | <offset> | [x, y, z]
  - { at: end,   type: halt }
```

## Materials & corners

Corners are built by hand (place rails in an L and they auto-curve). The
**materials / corner kit** entry — and the `railroad` category in the main
cheatsheet — give you the rails, redstone, deck palette and carts in one place.

## YAML & the CLI

The wizard writes a file like this (concrete coordinates, so re-running rebuilds
in the same spot):

```yaml
line:
  id: blue
  color: blue_concrete       # under-rail stripe
defaults:
  width: 3
  deck: polished_andesite    # prefer polished/brick variants
  walls: glass
  power_spacing: 9           # keep at 9
  light: lantern             # none | lantern | sea_lantern | glowstone | …
  light_style: pole          # pole | edge
  light_spacing: 8
segments:
  - { from: [120, 64, -30], dir: east, length: 128 }
stations:
  - { at: start, type: covered }
```

Drive it from the shell too:

```sh
mc-tui rail validate blue-line.yml          # schema check + command count
mc-tui rail compile  blue-line.yml          # print the commands
mc-tui rail run      blue-line.yml           # compile + stream over RCON
mc-tui rail run      blue-line.yml RodrigoDKi  # resolve from:player / dir:auto live
```

A `from: player` / `dir: auto` line is resolved from the named player's live
pose (`from: player` lands one block ahead of them); concrete coordinates need
no player.

!!! note "Remote servers"
    Everything is delivered as a batch of commands over a single RCON
    connection — no access to the world folder is required. The YAML is the
    portable source you keep and re-run.

!!! tip "Build it, then tweak it"
    Save a line as YAML, edit `length`, `deck`, `light` etc. by hand, and
    `mc-tui rail run` it again. Long runs are split automatically under the
    32 768-block `fill` limit.
