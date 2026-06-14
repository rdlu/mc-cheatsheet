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

## Kept at top speed

The track is mostly plain `rail`, with a **booster** every **8 blocks** — a
`powered_rail` sitting on its own `redstone_block` tucked into the deck. Each
booster powers itself, and the plain rails between simply coast, so the line
uses very little gold and there are never any *unpowered* powered-rails to brake
the cart. A booster every 8 blocks keeps a minecart pinned at top speed on the
flat and lines the boosters up with the even length presets (8/16/32…). Just
drop a minecart on the line and ride.

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

## Long lines in chunks (the end stop)

Building a very long line at once means riding blind past unloaded chunks. Easier
to lay it in pieces — and the **end stop** makes that safe. Turn it on (a buffer
block, e.g. `red_concrete`, one block past the last rail) and a cart can't fly
off the end: it stops at the buffer.

To continue, ride to the end, hop out, and **build the next line from there** — it
starts where you're standing, so its first rail lands on the buffer and
**replaces it**, seamlessly joining the two (a new line starts with a booster, so
the whole run stays at top speed). Repeat as far as you like.

## Stations

`[rail builder]` → **place a station** drops a stop at your position, oriented
to your facing:

- **halt** — an open platform with a lever-controlled launcher and corner
  lanterns
- **covered** — the same, plus a roof, pillars and hanging lanterns
- **terminus** — a **dead-end buffer** for the *end* of a line: the rail ends
  at a solid 2-high wall the cart bumps and stops against

A halt/covered station's middle is a `powered_rail` that's **unpowered by
default** (a brake), isolated from the line's power by short regular-rail
sections — so an arriving cart **stops**. Flip the **lever** beside it to
energise the launcher and the cart departs; flip it off to park.

!!! warning "Use a terminus at a line's end, not a halt"
    A halt/covered station has a *forward* departure rail — at the very end of a
    line it relaunches the cart straight off the edge. A **terminus** has no
    forward rail: the track just ends at a solid wall the cart bumps and stops
    against, and the wall keeps you from walking off the edge. To head back,
    nudge the cart the way you came; the line's boosters are bidirectional and
    carry it. Put a terminus wherever a line stops for good.

You can also add stations to a line's YAML directly:

```yaml
stations:
  - { at: start, type: covered }
  - { at: 64,    type: halt }      # at: start | end | <offset> | [x, y, z]
  - { at: end,   type: halt }
```

## Junctions (track switches)

`[rail builder]` → **place a junction** drops a switch one block ahead of you,
oriented to your facing:

- **t** — the through line stays straight; a branch peels off 90° to the
  `left` or `right`
- **y** — a two-way fork: the cart rests toward the side opposite the branch
  and diverts to the branch

**How the switch works.** A plain rail at a junction can't be flipped back and
forth by a lever alone — in Minecraft, powering a rail forces it into the
branch curve, but *un*-powering it doesn't switch it back (the rail keeps its
shape). So each junction is driven by two hidden **command blocks** that set the
rail's shape directly:

- a **lever** beside the junction fires the "divert" command block — flip it and
  the **next cart takes the branch**
- a **detector rail** just past the junction fires the "reset" command block —
  as the cart rides over it the switch **springs back to the through line**

So it's a one-shot diversion: flip the lever, send a cart down the branch, and
the switch resets itself for the traffic behind it. The command blocks sit clear
of the junction rail so they never power it by accident. (Command blocks must be
enabled on the server — they are by default; everything is placed for you over
RCON, nothing to craft.)

The branch ends in a short powered stub — **continue it** by building a new line
from its end (`place a junction` leaves you a rail to extend), exactly like
chaining line segments.

In YAML a junction overlays the line at any anchor:

```yaml
junctions:
  - { at: 64, kind: t, branch: right }   # at: start | end | <offset> | [x,y,z]
  - { at: 96, kind: y, branch: left }
```

Two roles fall out of this naturally: a **maintenance** switch out on the line
(walk up, flip the lever) and, since a junction can sit right by a stop,
passenger-style picking at a station. For a station that fans out to several
lines, the simplest layout is a **hub** — a cluster of single-exit stations you
walk between to change lines — rather than one multi-exit platform.

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
  power_spacing: 8           # booster every N blocks (aligns with the presets)
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
