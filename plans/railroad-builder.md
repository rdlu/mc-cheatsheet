# Railroad builder — design & reference

Status: **design agreed, implementation pending**
Last updated: 2026-06-14

A feature for mc-tui that builds **surface and air railroads** in Minecraft
over RCON: straight, always-powered lines laid from where your character is
standing and looking, plus drop-in stations. Curves are built by hand (a
give-kit makes that quick). Lines are authored as YAML so they're portable,
versionable, and re-runnable.

---

## 1. Goal & context

Building rail by hand — bridges, terrain-hugging causeways — is slow and
fiddly. We want a TUI flow where you stand where the line should start, look the
way it should go, pick a length, and the track appears: deck, rails, power, and
optional walls. Subway-style **line colors** mark which line you're on. A couple
of prebuilt **stations** give you somewhere to stop and depart.

This builds on the existing mc-tui (`bin/mc-tui`): a fish front-end over `mcrcon`
with `uv`-backed Python helpers (`scripts/follow-map.py`, `scripts/builder-data.py`).

### Hard constraints

- **The server is always remote.** We can only send commands over RCON — we
  cannot write datapack/`.mcfunction` files into the world folder. The command
  stream is the only delivery mechanism. (YAML is kept as the *source* format,
  not as on-disk Minecraft data.)
- **`/fill` is cuboid** (axis-aligned boxes) and capped at **32 768 blocks per
  command** — so we generate straight, axis-aligned segments and chunk long runs.
- `uv` is already a pinned tool in `mise.toml`, so a Python helper adds no new
  dependency.

---

## 2. Decisions log

Everything below was discussed and agreed before implementation:

| Topic | Decision |
|---|---|
| Line definition | **start + direction + length** |
| Start point | one block ahead of the player, at deck level (overridable) |
| Direction | **auto-detected from player facing** (yaw → cardinal), overridable |
| Length | free value, with presets **8 / 16 / 32 / 64 / 128 / 256** (powers of two tile cleanly) |
| Deck width | prompt **1 or 3** per build |
| Line color | **under-rail stripe** (center column); width-3 edges keep the stone palette |
| Power | plain `rail` with a `powered_rail` + `redstone_block` **booster** every `power_spacing` (default **9**); each booster is powered on its own, no relay — see §3 |
| Lighting | optional — a `light` block on **poles** (lamp posts), the deck **edge**, or the base **side** (hanging under the edge), every `light_spacing` (default 8); any block light stops mob spawns |
| End stop | optional `end_stop` buffer block past the last rail (stops a runaway cart); overwritten when you continue the line — for laying long runs in chunks |
| Stations | **parametric** (generated commands, not binary structures); two designs: **simple halt** + **covered stop** |
| Corners | built **by hand**; a give-kit supplies the materials |
| Compiler | **Python via `uv`** — single geometry engine; fish is the UI + RCON |
| Source format | **YAML**, one file per line, portable & versionable |
| Output | **RCON command stream only** (datapack export dropped — see constraints) |

---

## 3. Minecraft mechanics reference

The facts the generator depends on:

- **Rails need a solid block underneath.** Every rail layer sits on a support
  (deck) layer.
- **Rail orientation is a blockstate.** When placed by command, set it
  explicitly or auto-orientation is inconsistent:
  - run along **X** (east/west) → `rail[shape=east_west]`
  - run along **Z** (north/south) → `rail[shape=north_south]`
  - corners use `shape=south_east`, `north_east`, etc.
- **Powered rails must be powered, or they brake.** An *unpowered* `powered_rail`
  actively slows carts. The line avoids this entirely: it is plain `rail` with a
  **booster** (`powered_rail` on a `redstone_block`) only every `power_spacing`
  blocks. No powered rail is ever left unpowered, so nothing brakes.
- **Booster spacing:** each booster sits on its own `redstone_block` and is
  powered independently — there is **no powered-rail relay** in the design (the
  plain rails between boosters don't conduct, they just coast). So spacing is
  purely a *speed-maintenance* number, not a relay constraint. A single active
  booster keeps an occupied cart at top speed for tens of blocks on the flat;
  the default **9** is deliberately conservative (live-verified: a cart launched
  off a booster holds 0.4 b/tick = 8 m/s across the plain rails to the next).
  - History: an earlier design laid the **whole** line as `powered_rail` and
    leaned on the relay (≤ 8 each way), which forced spacing = 9 and was both
    gold-hungry and fragile (any unpowered powered-rail braked). Switching to
    plain-rail-plus-boosters removed the relay dependency and the brake risk.
- **Speed:** boosters every 9 blocks keep an occupied cart pinned at top speed
  (8 m/s) on flat ground, using a fraction of the gold.

### Facing detection

mc-tui already reads position via `data get entity <who> Pos`. Facing comes from
the sibling query:

```
data get entity <who> Rotation   →  [<yaw>f, <pitch>f]
```

Yaw maps to cardinals (normalize to `[0, 360)`):

| Yaw range | Facing | Unit (dx, dz) | Rail shape |
|---|---|---|---|
| 315–360 / 0–45 | **south** (+Z) | (0, +1) | `north_south` |
| 45–135 | **west** (−X) | (−1, 0) | `east_west` |
| 135–225 | **north** (−Z) | (0, −1) | `north_south` |
| 225–315 | **east** (+X) | (+1, 0) | `east_west` |

### Vertical frame

`Pos` Y is the player's feet (top surface of the block below). Defaults:

- **deck Y** = `floor(feetY) − 1` (the block you're standing on — the line
  extends the floor under your feet)
- **rail Y** = deck Y + 1
- **redstone** sits in the deck (deck Y), directly under the rail

All overridable at build time (e.g. raise the whole thing for a sky bridge).

---

## 4. Architecture

Clean split so geometry lives in exactly one place:

```
                  fish (bin/mc-tui)                     python (scripts/railroad.py)
        ┌────────────────────────────────┐           ┌──────────────────────────────┐
build → │ railroad_view: pickers collect │  YAML →   │ compile: YAML → command list │
wizard  │ answers → write a YAML doc      │  (stdin/  │ validate: schema checks       │
        │ player_pose: Pos+Rotation→dir   │  tmpfile) │ (geometry, stations, power,   │
        │ resolves player/auto → coords   │           │  fill chunking ≤ 32768)       │
        └───────────────┬────────────────┘           └───────────────┬──────────────┘
                        │                                            │ commands (stdout)
              saved *.yml │◄───────────────────────────────────────────┘
                        ▼
        rcon_exec_many: one mcrcon connection, commands as sequential args
                        ▼
                  remote server
```

- **fish owns RCON and the world.** It reads the player's pose, resolves
  `from: player` / `dir: auto` into concrete coordinates and a cardinal
  direction, streams the compiled commands, and persists saved lines.
- **Python owns geometry and YAML.** `railroad.py` is pure and offline: YAML in
  → commands out. No RCON, no world state, no randomness. This makes it easy to
  test and keeps the math in one language.
- The interactive builder is effectively a **YAML-authoring wizard**: it produces
  the same YAML you could write by hand, so "save as YAML" is free and the two
  front-ends (wizard / hand-written file) can't drift.

---

## 5. YAML schema

One file per line, kept in `~/.config/mc-tui/rail/<id>.yml`. Terse via
`defaults`; coordinates may be explicit, `player` (resolved live), or `end`
(chain from the previous segment).

```yaml
# ~/.config/mc-tui/rail/blue-line.yml
version: 1
line:
  id: blue
  name: "Blue Line"
  color: blue_concrete      # under-rail stripe + station marker

defaults:                   # applied to every segment unless overridden
  width: 3                  # 1 or 3
  deck: polished_andesite   # deck block — prefer polished/brick variants
  walls: glass              # none | open | <block id>  (open = accent edges, no barrier)
  wall_height: 1            # 1 or 2 (only when walls is a block)
  power_spacing: 9          # booster (powered_rail+redstone) every N rails (see §3)
  light: lantern            # none | <light block>  (lantern, sea_lantern, glowstone…)
  light_style: pole         # pole (lamp posts) | edge (on the deck edge) | side (under the edge)
  light_spacing: 8          # blocks between lights — <=24 stops all mob spawns
  light_side: both          # both | left | right
  end_stop: none            # none | <block>: a buffer past the last rail (cart stop)

segments:
  - from: [120, 64, -30]    # explicit; or `from: player`, or `from: end`
    dir: east               # n/s/e/w; or `dir: auto` (live player facing)
    length: 128
  - from: end               # continue where the previous segment stopped
    dir: north
    length: 64
    walls: none             # per-segment override

stations:
  - { at: start, type: covered }            # at: start | end | <offset int> | [x,y,z]
  - { at: 128, type: halt, name: "Midpoint" }
```

### Field semantics

- `from`: `[x,y,z]` is the **first rail block** — the riding surface, at player
  feet level; the deck is generated one block below. `player` → resolved by fish
  before compile. `end` → one step (in the new segment's direction) beyond the
  previous segment's last rail block; the corner between differently-directed
  segments is left for the give-kit.
- `dir`: `n`/`s`/`e`/`w` (or full words); `auto` → live player facing.
- `width`: `1` (just the rail + its deck) or `3` (rail + an accent/walkway block
  each side).
- `walls`: `none`/`open` → no barrier (width-3 edges are a flat accent walkway);
  any other value is the **barrier block id** (e.g. `glass`, `oak_fence`,
  `stone_brick_wall`) placed on the two edge columns from rail level up
  `wall_height` blocks. With width 1 the barrier floats immediately beside the rail.
- `power_spacing`: blocks between boosters (a `powered_rail` on a `redstone_block`
  amid plain rail). Default **9** is conservative; since each booster is powered
  independently (no relay) it can safely be larger to save gold (§3).
- `light`: `none`, or a light block id (`lantern`, `sea_lantern`, `glowstone`,
  `end_rod`, …). When set, lights are placed every `light_spacing`.
- `light_style`: `pole` (a 3-tall post just beyond the deck edge with the light
  on top — lamp posts), `edge` (the light sitting on top of the deck edge), or
  `side` (the light on the flank of the base — lanterns hang under the edge,
  full blocks like `sea_lantern` sit flush below it).
- `light_spacing`: blocks between lights (default 8). Since any block light > 0
  stops hostile spawns, ≤ 24 keeps the whole track spawn-proof.
- `light_side`: `both` / `left` / `right`.
- `end_stop`: `none`, or a block placed one past the last rail as a **buffer** so
  a runaway cart can't fly off the end. It sits on the centre line at rail level,
  so building the next chunk forward (its first rail lands there) overwrites it
  cleanly — ideal for laying long lines in pieces. The join stays at speed: a
  continuation starts with a booster at its first rail (offset 0; see §3).
- `stations[].at`: `start`, `end`, an integer **offset along the line**, or
  explicit `[x,y,z]`.

---

## 6. Command generation (geometry)

For one segment — direction unit `(dx, dz)`, perpendicular `(px, pz)` (the
direction rotated 90°), start `S = (sx, sy, sz)`, length `L`, width `W`, deck
block `D`, color `C`, walls — the generator emits, in order:

1. **Deck edges** (width 3 only), at `sy`, perpendicular offset ±1, full length → `D`
2. **Under-rail stripe**, at `sy`, offset 0, full length → `C` (or `D` if no color)
3. **Rail**, at `sy+1`, offset 0, full length → `rail[shape=<axis>]` (plain)
4. **Boosters**, every `power_spacing` blocks at offset 0: a `redstone_block` at
   `sy` (overwrites the stripe there) with a `powered_rail[shape=<axis>]` set on
   top at `sy+1` (overwrites the plain rail there)
5. **Walls** (if `walls` is a block), at `sy+1` (and `sy+2` if `wall_height=2`),
   perpendicular offset ±1, full length → the wall block
6. **Lighting** (if `light` set), every `light_spacing` on the chosen side(s):
   `pole` = a 3-tall deck-block post just beyond the edge with the light on top;
   `edge` = the light on top of the deck edge; `side` = the light under the deck
   edge (lanterns get `hanging=true`)

Each cuboid layer is a single `fill`. If a layer would exceed 32 768 blocks it's
split into sequential chunks along the direction axis.

### Worked example

Player at ≈ `(119, 64, −30)` facing **east**, width 3, deck diorite, color
`blue_concrete`, glass walls, length 128, `power_spacing` 9. Deck Y = 63, rail Y
= 64, start x = 120, center z = −30, run east to x = 247.

```
# Blue Line · seg 0 · east · len 128 · width 3 · deck diorite · walls glass
fill 120 63 -31 247 63 -31 minecraft:diorite          # deck edge
fill 120 63 -29 247 63 -29 minecraft:diorite          # deck edge
fill 120 63 -30 247 63 -30 minecraft:blue_concrete    # under-rail stripe
fill 120 64 -30 247 64 -30 minecraft:rail[shape=east_west]   # plain track
setblock 120 63 -30 minecraft:redstone_block          # booster every 9 …
setblock 120 64 -30 minecraft:powered_rail[shape=east_west]
setblock 129 63 -30 minecraft:redstone_block
setblock 129 64 -30 minecraft:powered_rail[shape=east_west]
# … through x=246  (15 boosters for 128 length)
fill 120 64 -31 247 64 -31 minecraft:glass            # wall
fill 120 64 -29 247 64 -29 minecraft:glass            # wall
```

≈ 6 fills + ~30 setblocks ≈ 36 commands — one RCON round-trip.

---

## 7. Stations (parametric)

Stations are generated commands oriented to the travel direction, anchored at a
rail block on the line. Orientation uses a helper that maps `(forward, right,
up)` offsets to world `(x, y, z)` for the cardinal direction, so one definition
serves all four. `at` resolves to an anchor: `start`, `end`, an integer offset
along the line, or explicit `[x,y,z]`. A station **overwrites** the line's rails
at its location (it's emitted after the segments). Placing one standalone (the
TUI's "place a station") uses a length-1 segment to carry the anchor, which the
station then overwrites — so only the station shows.

The stop mechanism (live-verified by probing `powered_rail[powered=…]`):

- A 5-long × 3-wide platform deck, one block below rail level.
- Track through it: `powered_rail` at both ends (with a `redstone_block` under
  each so the approach/departure stay powered), **regular `rail`** at ±1 to
  isolate the launcher, and a **launcher** `powered_rail` in the centre with *no*
  source under it — so it sits **unpowered = a brake** and the cart stops.
- A **lever** on a solid post beside the launcher: flip it on and the post
  strong-powers the launcher → the cart departs; flip off to park. (A lever, not
  a button, so a parked cart stays put until you choose to leave.) Verified: lever
  off → launcher unpowered, lever on → powered.

### Simple halt

The platform + launcher above, open, with a `lantern` on each of the four
platform corners and a line-colour marker block on the far edge.

### Covered stop

The halt, plus a 3-wide roof two blocks up, four corner pillars, and two
`lantern[hanging=true]` under the roof.

### Terminus (dead-end buffer)

For the **end** of a line. A halt/covered station has a *forward* departure
`powered_rail`; at a line's end that flings an overshooting or relaunched cart
off the edge (hit live — a ridden cart's momentum carried past the brake and the
departure rail launched it into the void). The terminus removes the forward rail
entirely: approach coasts in to an unpowered `powered_rail` brake, then a
**3-wide × 2-high wall one block ahead** stops the cart dead and walls off the
platform edge. The lever still launches — but with the wall on the far side the
cart departs **backwards**, the way it came. Verified live: a Motion 0.8 cart
(double max speed) stopped at the brake against the wall, nothing escaped.

All three are `fill`/`setblock` only — hand-editable, no binary `.nbt`, and they
take the line's deck material and colour.

---

## 8. RCON delivery

`rcon_exec_many` sends a batch in a **single `mcrcon` invocation** — commands are
positional args run sequentially over one connection
(`mcrcon -c "cmd1" "cmd2" …`), instead of one TCP connect per command (important
for a remote server). A typical line is well under 40 commands; very large lines
are split into batches of ~100.

The build action menu offers:

- **run over RCON** (primary)
- **copy** — newline dump for reference (chat can't paste multi-line; this is
  for inspection or pasting into the RCON console)
- **save as YAML** — persist to `~/.config/mc-tui/rail/<id>.yml`

---

## 9. UX / menus

New top-level entry `[rail builder]` in the main menu (beside `[map]`); the
`railroad` give-kits show up as their own browsable catalog category. Backed by
`railroad_view`:

- **Build a line** → pick player → `player_pose` fills start/dir (overridable) →
  height offset / width / length / deck / color / walls / lighting → preview →
  action menu (run / copy / save as YAML)
- **Place a station** → `halt` | `covered` → deck / color → preview → action menu
- **Load a saved line** → pick a `*.yml` → compile → action menu
- **Materials / corner kit** → jumps to the `railroad` catalog category

### Give-kits (catalog `railroad` category)

Grouped `give` rows like the god-gear menu — reuse the existing `command_view`,
no new logic:

- **Rail kit** — 64 powered rails, 64 rails, redstone blocks, detector/activator
  rails, minecarts
- **Corner kit** — rails + buttons (curves auto-form when you place rails in an L)
- **Stone palette** — the *aesthetically pleasing* polished/brick variants (not
  the rough base blocks): `polished_andesite`, `polished_diorite`,
  `polished_granite`, `stone_bricks`, `smooth_stone`, `deepslate_bricks`,
  `deepslate_tiles`, `polished_deepslate`, `polished_blackstone_bricks`,
  `bricks`, `smooth_sandstone`, `smooth_quartz` — as quick gives and as the
  deck-material picker options
- **Color set** — all 16 concrete colors for line marking
- **Carts** — minecart, chest_minecart, hopper_minecart

---

## 10. CLI surface

```
mc-tui rail compile <file.yml>   # print the generated commands
mc-tui rail run <file.yml>       # compile + stream over RCON
mc-tui rail validate <file.yml>  # schema check
```

(Interactive use goes through `[railroad]` in the TUI.)

---

## 11. Files touched

- `scripts/railroad.py` — **new**: compiler (`compile` / `validate`), geometry +
  stations + power + chunking; reads YAML (PyYAML via `uv run`).
- `bin/mc-tui` — `player_pose`, `yaw_to_dir`, `railroad_view` (+ sub-flows),
  `rcon_exec_many`, `[railroad]` wiring in `main` + `preview_cat`, `rail` CLI verb,
  and the `railroad` rows in `catalog`.
- `~/.config/mc-tui/rail/*.yml` — saved lines (runtime, not in repo).
- Docs: a public page later if wanted; `mise` task `rail`; README mention.

---

## 12. Implementation plan

1. `scripts/railroad.py` — line compiler + YAML schema + `compile`/`validate`.
2. fish `player_pose` / `yaw_to_dir`.
3. fish `railroad_view` build-line flow (run / copy / save).
4. `railroad.py` stations (halt + covered) → fish station flow.
5. `rcon_exec_many` batching + `mc-tui rail` CLI verb.
6. `railroad` catalog give-kits.
7. Docs + `mise` task + README.

---

## 13. Junctions / switches (T + Y)

A `junctions:` list overlays a line with single-branch track switches. Each entry
resolves an anchor on the track (`start | end | <offset> | [x,y,z]`, same as
stations) and lays a switch oriented to travel:

- **t** — through line stays straight; a branch peels off 90° (`left` | `right`).
- **y** — two-way fork: rests toward the side opposite `branch`, diverts to it.

### Why command blocks (the live finding)

The plan was a lever-driven redstone switch. Probing the real 26.1 Fabric server
(`execute if block … rail[shape=…]`) showed that **doesn't work both ways**:

- A bare rail at a 3-neighbour junction picks its shape by priority (often the
  "wrong" curve that ignores the incoming side).
- **Gaining** redstone power forces a specific curve (e.g. `south_west`).
- **Losing** power does *not* switch it back — the rail clings to its current
  valid shape. Re-placing the branch rail or toggling a neighbour didn't reset it
  either. Only an explicit `setblock` (or full re-place) reliably sets the shape.

So a passive lever can divert a cart but can't restore the through line — which
killed the lever/redstone plan and the long-distance "control from afar" idea
alike. The reliable primitive is `setblock`-the-shape, and the in-world way to
fire a `setblock` is a **command block** (enabled by default; placed over RCON).

### Mechanism (verified end to end)

Two impulse command blocks drive the junction rail:

- **divert** CB ← a **lever** beside the junction. Flip it → next cart branches.
- **reset-to-main** CB ← a **detector rail** one block past the junction. The
  cart rides over it → switch springs back to the through line.

Placement rules learned the hard way:

- The command blocks sit *clear* of the junction rail (diagonal / ≥2 away) so
  powering them never throws the switch via stray rail power.
- A **one-block coast** separates the branch re-accel `powered_rail` (and its
  `redstone_block`) from the reset command block. Adjacent, the redstone_block
  pins the reset CB permanently on, so the detector can never pulse it — the
  switch would never reset. Found via a live cart test, then fixed.

A summoned minecart confirmed the loop: junction set to divert → cart took the
branch → detector reset the switch to straight as it passed.

### Roles & hubs

Two roles fall out: **maintenance** (walk to a mid-line switch, flip the lever)
and passenger-style picking where a junction sits by a stop. Multi-exit stations
(3+ way ladders, interlocks) are *not* built — the simpler layout is a **hub**:
a cluster of single-exit stations the player walks between to change lines.

## 14. Future ideas (out of scope for v1)

- **Auto corners** — generate L-turns between chained segments (zigzag stairs for
  diagonals) instead of leaving them to the give-kit.
- **Datapack export** — only useful if a world folder is ever locally reachable;
  the compiler is already structured so a `pack` target is a thin add-on.
- **Structure-based stations** — `type: structure ns:my_station` via
  `/place template`, for pixel-perfect custom stops (needs the structure shipped
  in a datapack).
- **Signals / sidings** — detector rails + redstone for stop-on-occupied (the
  switchable-junction half of this is now built — see §13).
- **Terrain-following lines** — segmented Y steps that hug the ground (denser
  power on slopes).
