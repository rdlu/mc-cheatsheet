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

    end_block = [sx + dx * (length - 1), ry, sz + dz * (length - 1)]
    return cmds, end_block


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
    if data.get("stations"):
        n = len(data["stations"])
        print(f"railroad: skipping {n} station(s) — not implemented yet",
              file=sys.stderr)
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
            segments, color = resolve(data, pose)
            total = sum(len(generate_segment(s, color)[0]) for s in segments)
            name = (data.get("line") or {}).get("id", "?")
            print(f"OK — line {name!r}: {len(segments)} segment(s), "
                  f"~{total} command(s)")
    except RailError as e:
        print(f"railroad: {e}", file=sys.stderr)
        sys.exit(2)
    except FileNotFoundError as e:
        print(f"railroad: file not found: {e.filename}", file=sys.stderr)
        sys.exit(2)


if __name__ == "__main__":
    main()
