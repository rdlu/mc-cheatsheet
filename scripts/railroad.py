# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml"]
# ///
"""railroad.py — compile a railroad YAML definition into Minecraft commands.

mc-tui's railroad builder authors a line as YAML (see plans/railroad-builder.md)
and this script turns it into a flat list of `fill`/`setblock` commands that the
fish front-end streams over RCON. It is pure and offline — YAML in, commands out,
no RCON and no world state — so all the track geometry lives in exactly one place.

Usage:
    uv run scripts/railroad.py compile  line.yml   # commands -> stdout
    uv run scripts/railroad.py validate line.yml   # schema check (+ command count)
    # use `-` as the filename to read the YAML from stdin

Coordinates in the YAML are absolute integers and `from.y` is the RAIL level (the
riding surface). The deck is generated one block below, with the power blocks
tucked into the deck directly under the rail. `from: player` / `dir: auto` are
resolved by the TUI before they reach this script (it reads your live position
and facing); `from: end` chains from the previous segment and is resolved here.
"""
import argparse
import sys

import yaml

CHUNK = 32768  # max blocks per /fill

# direction -> unit step (dx, dz); accepts full names and single letters
DIRS = {
    "north": (0, -1), "n": (0, -1),
    "south": (0, 1), "s": (0, 1),
    "east": (1, 0), "e": (1, 0),
    "west": (-1, 0), "w": (-1, 0),
}
CANON = {"n": "north", "s": "south", "e": "east", "w": "west"}

DEFAULTS = {
    "width": 3,                 # 1 (just the rail) or 3 (rail + an edge each side)
    "deck": "polished_andesite",  # deck block — prefer polished/brick variants
    "walls": "none",     # none | open | <block id> (e.g. glass, oak_fence)
    "wall_height": 1,    # 1 or 2, only when walls is a block
    "power_spacing": 9,  # redstone_block under the rail every N blocks; see below
    "light": "none",     # none | <light block id> (e.g. lantern, sea_lantern)
    "light_style": "pole",   # pole (lamp posts) | edge (on the deck edge) | side (under the edge)
    "light_spacing": 8,  # blocks between lights; <=24 stops all mob spawns
    "light_side": "both",  # both | left | right
}


class RailError(Exception):
    """A problem with the definition the user can fix."""


# --- helpers -----------------------------------------------------------------

def ns(block):
    """Prefix `minecraft:` when no namespace is present (before any blockstate)."""
    head = block.split("[", 1)[0]
    return block if ":" in head else f"minecraft:{block}"


def canon_dir(value):
    d = str(value).strip().lower()
    if d not in DIRS:
        raise RailError(f"unknown direction: {value!r} (use n/s/e/w)")
    return CANON.get(d, d)


def parse_pose(text):
    """Parse a `"X Y Z DIR"` pose string (from the TUI) into a dict, or None."""
    if not text:
        return None
    parts = text.split()
    if len(parts) != 4:
        raise RailError('--pose must be "X Y Z DIR" (e.g. "838 69 12 north")')
    try:
        return {"x": int(parts[0]), "y": int(parts[1]), "z": int(parts[2]),
                "dir": canon_dir(parts[3])}
    except ValueError:
        raise RailError("--pose coordinates must be integers")


def _int(value, field, idx):
    try:
        return int(value)
    except (TypeError, ValueError):
        raise RailError(f"segment {idx}: `{field}` must be an integer")


def fill(x1, y1, z1, x2, y2, z2, block):
    return f"fill {x1} {y1} {z1} {x2} {y2} {z2} {ns(block)}"


def setblock(x, y, z, block):
    return f"setblock {x} {y} {z} {ns(block)}"


# --- geometry ----------------------------------------------------------------

def generate_segment(seg, color):
    """Return (commands, end_block) for one resolved segment.

    `seg` has concrete `from`/`dir`/`length` and merged defaults. `end_block` is
    the segment's last rail coordinate, used for `from: end` chaining.
    """
    direction = seg["dir"]
    dx, dz = DIRS[direction]
    px, pz = (-dz, dx)               # perpendicular unit (the "side" axis)
    sx, ry, sz = seg["from"]         # from.y is the rail (riding) level
    dy = ry - 1                      # deck sits one below the rail
    length = seg["length"]
    width = seg["width"]
    deck = seg["deck"]
    walls = str(seg["walls"]).strip().lower()
    wall_height = seg["wall_height"]
    spacing = max(1, seg["power_spacing"])
    shape = "east_west" if dx else "north_south"

    def fills_along(offset, y, block):
        """Fill blocks 0..length-1 at perpendicular `offset` and height `y`,
        chunked so no single /fill exceeds CHUNK blocks (the run is 1 wide)."""
        i = 0
        while i < length:
            n = min(CHUNK, length - i)
            j = i + n - 1
            yield fill(sx + dx * i + px * offset, y, sz + dz * i + pz * offset,
                       sx + dx * j + px * offset, y, sz + dz * j + pz * offset,
                       block)
            i += n

    cmds = []
    if width >= 3:                              # deck edges (walkway / accent)
        cmds += fills_along(+1, dy, deck)
        cmds += fills_along(-1, dy, deck)
    cmds += fills_along(0, dy, color or deck)   # under-rail stripe (line colour)
    cmds += fills_along(0, ry, f"powered_rail[shape={shape}]")
    # Power: a redstone_block under a rail energises it, and an energised powered
    # rail relays power to up to 8 rails each way. So one source per 9 rails gives
    # gapless coverage. Critically, place sources in INCREASING order: each then
    # lands on a still-unpowered rail and kicks off a fresh relay. Dropping a
    # source under an already-powered rail does NOT start a new relay (the rail's
    # state doesn't change), which is why spacing <= 8 stalls after the 1st source.
    for i in range(0, length, spacing):
        cmds.append(setblock(sx + dx * i, dy, sz + dz * i, "redstone_block"))
    if walls not in ("none", "open", ""):       # side barrier (a block id)
        for h in range(wall_height):
            cmds += fills_along(+1, ry + h, walls)
            cmds += fills_along(-1, ry + h, walls)

    # lighting (optional): lamp posts beside the track, or lanterns on the edge.
    # Any block light > 0 stops hostile spawns, so a lit track is a safe track.
    light = str(seg["light"]).strip().lower()
    if light not in ("none", "off", ""):
        style = str(seg["light_style"]).strip().lower()
        lspace = max(1, seg["light_spacing"])
        sides = {"left": (-1,), "right": (1,), "both": (-1, 1)}.get(
            str(seg["light_side"]).lower(), (-1, 1))

        def at(i, o, y):
            return (sx + dx * i + px * o, y, sz + dz * i + pz * o)

        pole_off = width // 2 + 1                # just beyond the deck edge
        hanging = light.split(":")[-1] in ("lantern", "soul_lantern")
        for i in range(0, length, lspace):
            for s in sides:
                if style == "edge":              # light sitting on the deck edge
                    cmds.append(setblock(*at(i, s, dy), deck))   # support nub
                    cmds.append(setblock(*at(i, s, ry), light))
                elif style == "side":            # light on the flank of the base
                    cmds.append(setblock(*at(i, s, dy), deck))   # anchor to hang from
                    blk = f"{light}[hanging=true]" if hanging else light
                    cmds.append(setblock(*at(i, s, dy - 1), blk))
                else:                            # pole: 3-tall post + light on top
                    o = s * pole_off
                    cmds.append(fill(*at(i, o, dy), *at(i, o, dy + 2), deck))
                    cmds.append(setblock(*at(i, o, dy + 3), light))

    end_block = [sx + dx * (length - 1), ry, sz + dz * (length - 1)]
    return cmds, end_block


# --- stations ----------------------------------------------------------------

def station_anchor(at, segments):
    """Resolve a station `at` (start | end | offset | [x,y,z]) to a world rail
    anchor and the travel direction there."""
    if isinstance(at, bool):
        raise RailError("station `at` must be start/end, an offset, or [x,y,z]")
    if isinstance(at, str):
        if at.lower() == "start":
            s = segments[0]
            return list(s["from"]), s["dir"]
        if at.lower() == "end":
            s = segments[-1]
            dx, dz = DIRS[s["dir"]]
            n = s["length"] - 1
            return [s["from"][0] + dx * n, s["from"][1], s["from"][2] + dz * n], s["dir"]
        raise RailError(f"station `at: {at}` — use start/end, an offset, or [x,y,z]")
    if isinstance(at, (list, tuple)) and len(at) == 3:
        return [int(v) for v in at], segments[0]["dir"]
    if isinstance(at, int):
        off = at
        for s in segments:
            if off < s["length"]:
                dx, dz = DIRS[s["dir"]]
                return [s["from"][0] + dx * off, s["from"][1],
                        s["from"][2] + dz * off], s["dir"]
            off -= s["length"]
        s = segments[-1]                       # past the end -> clamp to last rail
        dx, dz = DIRS[s["dir"]]
        n = s["length"] - 1
        return [s["from"][0] + dx * n, s["from"][1], s["from"][2] + dz * n], s["dir"]
    raise RailError(f"station `at: {at}` — use start/end, an offset, or [x,y,z]")


def generate_station(anchor, direction, deck, color, kind):
    """Commands for a station centred on `anchor` (a rail block), oriented to
    `direction`. A 5-long platform with a lever-launcher stop in the middle:
    the centre powered rail is isolated by regular rails so it stays unpowered
    (a brake) until the lever energises it, launching the cart onward.
    """
    ax, ay, az = anchor
    dx, dz = DIRS[direction]
    rx, rz = (-dz, dx)                         # "right" relative to travel
    shape = "east_west" if dx else "north_south"

    def w(f, r, u):                            # forward/right/up -> world x,y,z
        return (ax + f * dx + r * rx, ay + u, az + f * dz + r * rz)

    cmds = []
    # platform: 5 (forward) x 3 (sideways) deck, one below rail level
    a = w(-2, -1, -1)
    b = w(2, 1, -1)
    cmds.append(fill(*a, *b, deck))
    # track: powered ends, regular-rail isolation, launcher in the centre
    layout = {-2: "powered_rail", -1: "rail", 0: "powered_rail",
              1: "rail", 2: "powered_rail"}
    for f, rail in layout.items():
        x, y, z = w(f, 0, 0)
        cmds.append(setblock(x, y, z, f"{rail}[shape={shape}]"))
    # power the two end rails (approach brake-free + departure boost); the
    # launcher (f=0) gets no source, so it brakes until the lever fires it
    for f in (-2, 2):
        x, y, z = w(f, 0, -1)
        cmds.append(setblock(x, y, z, "redstone_block"))
    # lever-launcher: a solid post beside the centre rail, lever on top of it
    cmds.append(setblock(*w(0, 1, 0), deck))
    cmds.append(setblock(*w(0, 1, 1), "lever[face=floor]"))
    # line-colour marker on the far edge
    if color:
        cmds.append(setblock(*w(0, -1, 0), color))

    if kind == "covered":
        cmds.append(fill(*w(-2, -1, 3), *w(2, 1, 3), deck))      # roof
        for f, r in ((-2, -1), (-2, 1), (2, -1), (2, 1)):       # corner pillars
            cmds.append(fill(*w(f, r, 1), *w(f, r, 2), deck))
        for f in (-1, 1):                                       # hanging lights
            cmds.append(setblock(*w(f, 0, 2), "lantern[hanging=true]"))
    else:                                                       # halt: open
        for f, r in ((-2, -1), (-2, 1), (2, -1), (2, 1)):       # corner lanterns
            cmds.append(setblock(*w(f, r, 0), "lantern"))
    return cmds


# --- definition loading & resolution -----------------------------------------

def load(path):
    text = sys.stdin.read() if path == "-" else open(path, encoding="utf-8").read()
    try:
        data = yaml.safe_load(text)
    except yaml.YAMLError as e:
        raise RailError(f"invalid YAML: {e}")
    if not isinstance(data, dict):
        raise RailError("the definition must be a YAML mapping")
    return data


def resolve(data, pose=None):
    """Merge defaults into every segment, validate, and resolve placeholders.

    Resolves `from: end` (chain from the previous segment) always, and
    `from: player` / `dir: auto` when a `pose` dict is supplied (the TUI reads
    the live position + facing). `from: player` lands one block *ahead* of the
    player in the resolved direction. Returns (segments, color).
    """
    line = data.get("line") or {}
    defaults = data.get("defaults") or {}
    color = line.get("color") or defaults.get("color")

    raw = data.get("segments")
    if not isinstance(raw, list) or not raw:
        raise RailError("`segments` must be a non-empty list")

    out = []
    prev_end = None
    for idx, seg in enumerate(raw):
        if not isinstance(seg, dict):
            raise RailError(f"segment {idx}: must be a mapping")
        m = {**DEFAULTS, **defaults, **seg}

        d = m.get("dir")
        if str(d).lower() == "auto":
            if not pose:
                raise RailError(f"segment {idx}: `dir: auto` needs a facing — "
                                "build via the TUI, or pass a player to "
                                "`mc-tui rail`")
            d = pose["dir"]
        m["dir"] = canon_dir(d)

        frm = m.get("from")
        if isinstance(frm, str) and frm.lower() == "player":
            if not pose:
                raise RailError(f"segment {idx}: `from: player` needs a position "
                                "— build via the TUI, or pass a player to "
                                "`mc-tui rail`")
            dx, dz = DIRS[m["dir"]]
            frm = [pose["x"] + dx, pose["y"], pose["z"] + dz]  # one block ahead
        if isinstance(frm, str) and frm.lower() == "end":
            if prev_end is None:
                raise RailError(f"segment {idx}: `from: end` but there is no "
                                "previous segment to chain from")
            ndx, ndz = DIRS[m["dir"]]
            frm = [prev_end[0] + ndx, prev_end[1], prev_end[2] + ndz]
        if not (isinstance(frm, (list, tuple)) and len(frm) == 3
                and all(isinstance(v, (int, float)) and not isinstance(v, bool)
                        for v in frm)):
            raise RailError(f"segment {idx}: `from` must be [x, y, z], `player`, "
                            "or `end`")
        m["from"] = [int(v) for v in frm]

        m["length"] = _int(m.get("length"), "length", idx)
        if m["length"] < 1:
            raise RailError(f"segment {idx}: `length` must be >= 1")
        m["width"] = _int(m["width"], "width", idx)
        if m["width"] not in (1, 3):
            raise RailError(f"segment {idx}: `width` must be 1 or 3")
        m["wall_height"] = _int(m["wall_height"], "wall_height", idx)
        if m["wall_height"] not in (1, 2):
            raise RailError(f"segment {idx}: `wall_height` must be 1 or 2")
        m["power_spacing"] = _int(m["power_spacing"], "power_spacing", idx)
        if m["power_spacing"] < 1:
            raise RailError(f"segment {idx}: `power_spacing` must be >= 1")
        if str(m["light_style"]).lower() not in ("pole", "edge", "side"):
            raise RailError(f"segment {idx}: `light_style` must be pole, edge or side")
        if str(m["light_side"]).lower() not in ("both", "left", "right"):
            raise RailError(f"segment {idx}: `light_side` must be both/left/right")
        m["light_spacing"] = _int(m["light_spacing"], "light_spacing", idx)
        if m["light_spacing"] < 1:
            raise RailError(f"segment {idx}: `light_spacing` must be >= 1")

        out.append(m)
        dx, dz = DIRS[m["dir"]]
        prev_end = [m["from"][0] + dx * (m["length"] - 1), m["from"][1],
                    m["from"][2] + dz * (m["length"] - 1)]
    return out, color


def compile_cmds(data, pose=None):
    segments, color = resolve(data, pose)
    cmds = []
    for seg in segments:
        seg_cmds, _ = generate_segment(seg, color)
        cmds += seg_cmds
    deck = segments[0]["deck"]
    for st in (data.get("stations") or []):
        if not isinstance(st, dict):
            raise RailError("each station must be a mapping")
        kind = str(st.get("type", "halt")).lower()
        if kind not in ("halt", "covered"):
            raise RailError(f"station type `{st.get('type')}` — use halt or covered")
        anchor, direction = station_anchor(st.get("at", "start"), segments)
        cmds += generate_station(anchor, direction, deck, color, kind)
    return cmds


# --- cli ---------------------------------------------------------------------

def main():
    p = argparse.ArgumentParser(
        description="Compile a railroad YAML definition into Minecraft commands.")
    sub = p.add_subparsers(dest="cmd", required=True)
    for name, help_ in (("compile", "emit commands to stdout"),
                        ("validate", "schema check + command count")):
        sp = sub.add_parser(name, help=help_)
        sp.add_argument("file", help="YAML file, or - for stdin")
        sp.add_argument("--pose", metavar='"X Y Z DIR"',
                        help="live player pose to resolve from:player / dir:auto")
    args = p.parse_args()

    try:
        pose = parse_pose(args.pose)
        data = load(args.file)
        if args.cmd == "compile":
            cmds = compile_cmds(data, pose)
            name = (data.get("line") or {}).get("id", "line")
            print(f"railroad: {name} -> {len(cmds)} command(s)", file=sys.stderr)
            print("\n".join(cmds))
        else:  # validate
            segments, _ = resolve(data, pose)
            total = len(compile_cmds(data, pose))
            name = (data.get("line") or {}).get("id", "?")
            nst = len(data.get("stations") or [])
            print(f"OK — line {name!r}: {len(segments)} segment(s), "
                  f"{nst} station(s), {total} command(s)")
    except RailError as e:
        print(f"railroad: {e}", file=sys.stderr)
        sys.exit(2)
    except FileNotFoundError as e:
        print(f"railroad: file not found: {e.filename}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
