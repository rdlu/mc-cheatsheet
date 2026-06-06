# /// script
# requires-python = ">=3.11"
# dependencies = ["websockets"]
# ///
"""Live "follow map": open chunkbase.com/apps/seed-map in a Chromium window and
re-center it on a Minecraft player's position every few seconds.

Chunkbase reads the view (seed, dimension, x, z, zoom) only from the URL hash at
load time — it does not pan on hashchange — so each update reloads the tab via
the DevTools protocol (Page.navigate). Player positions come from RCON through
`mc-tui __loc <player>`, so this script needs no RCON details of its own.

Invoked by `mc-tui follow <player>` / the [map] → FOLLOW menu entry; not meant to
be run by hand, but you can:

    uv run scripts/follow-map.py --mc-tui ./bin/mc-tui --player Alice \
        --seed -89749131821109917 --platform java_26_1 --interval 10
"""
import argparse
import asyncio
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import urllib.request

import websockets

URL = ("https://www.chunkbase.com/apps/seed-map"
       "#seed={seed}&platform={platform}&dimension={dim}&x={x}&z={z}&zoom={zoom}")

DIM_LABEL = {"overworld": "Overworld", "nether": "Nether", "end": "The End"}


def find_chromium():
    for name in ("chromium", "chromium-browser", "google-chrome-stable",
                 "google-chrome", "brave"):
        path = shutil.which(name)
        if path:
            return path
    sys.exit("follow-map: no chromium/chrome binary found")


def player_loc(mc_tui, player):
    """Return (dim, x, z) for an online player, or None."""
    try:
        out = subprocess.run([mc_tui, "__loc", player], capture_output=True,
                             text=True, timeout=15).stdout.split()
    except subprocess.TimeoutExpired:
        return None
    if len(out) == 3:
        return out[0], out[1], out[2]
    return None


async def cdp(ws, state, method, params=None):
    state["id"] += 1
    mid = state["id"]
    await ws.send(json.dumps({"id": mid, "method": method, "params": params or {}}))
    while True:
        msg = json.loads(await ws.recv())
        if msg.get("id") == mid:
            return msg


async def page_ws_url(port, want_url, tries=60):
    for _ in range(tries):
        try:
            tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{port}/json"))
            for t in tabs:
                if t.get("type") == "page" and "chunkbase" in t.get("url", want_url):
                    return t["webSocketDebuggerUrl"]
            # fall back to any page target
            for t in tabs:
                if t.get("type") == "page":
                    return t["webSocketDebuggerUrl"]
        except Exception:
            pass
        await asyncio.sleep(0.25)
    return None


def read_devtools_port(profile, tries=60):
    portfile = os.path.join(profile, "DevToolsActivePort")
    for _ in range(tries):
        try:
            with open(portfile) as f:
                return int(f.readline().strip())
        except (FileNotFoundError, ValueError):
            time.sleep(0.25)
    return None


async def run(args):
    chromium = find_chromium()
    seed, platform, zoom = args.seed, args.platform, args.zoom

    # initial position (player's current spot, else spawn)
    loc = player_loc(args.mc_tui, args.player)
    if loc is None:
        print(f"follow-map: {args.player} isn't online yet — starting at spawn, "
              "will jump in when they appear")
        loc = ("overworld", "0", "0")
    start_url = URL.format(seed=seed, platform=platform, dim=loc[0],
                           x=loc[1], z=loc[2], zoom=zoom)

    profile = tempfile.mkdtemp(prefix="mc-follow-")
    proc = subprocess.Popen(
        [chromium, f"--app={start_url}", f"--user-data-dir={profile}",
         "--remote-debugging-port=0", "--remote-allow-origins=*",
         "--no-first-run", "--no-default-browser-check",
         "--window-size=1100,900"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    try:
        port = read_devtools_port(profile)
        if not port:
            sys.exit("follow-map: chromium did not expose a debugging port")
        ws_url = await page_ws_url(port, start_url)
        if not ws_url:
            sys.exit("follow-map: could not find the chunkbase tab")

        last = loc
        cur_zoom = zoom  # preserved across reloads (updated from the live page)
        # ping_interval=None: Chrome's CDP endpoint doesn't answer WS keepalive
        # pings, so the default keepalive would kill the idle connection during
        # our sleeps. We don't need Page.enable either — Page.navigate works
        # without it, and skipping it keeps the socket free of event spam.
        async with websockets.connect(ws_url, max_size=None,
                                      ping_interval=None) as ws:
            state = {"id": 0}
            print(f"following {args.player} — re-centering every {args.interval}s. "
                  "Close the window or press Ctrl-C to stop.")
            while proc.poll() is None:
                await asyncio.sleep(args.interval)
                if proc.poll() is not None:
                    break
                # Chunkbase writes the live view (incl. zoom) into the URL hash
                # as you scroll, so read it back and keep your chosen zoom.
                try:
                    href = (await cdp(ws, state, "Runtime.evaluate",
                            {"expression": "location.href", "returnByValue": True})
                            )["result"]["result"]["value"]
                    m = re.search(r"[#&]zoom=([0-9.]+)", href or "")
                    if m:
                        cur_zoom = m.group(1)
                except websockets.ConnectionClosed:
                    break
                except Exception:
                    pass
                loc = player_loc(args.mc_tui, args.player)
                if loc is None:
                    print(f"  {args.player} offline — holding last position")
                    continue
                if loc == last:
                    continue
                last = loc
                dim, x, z = loc
                url = URL.format(seed=seed, platform=platform, dim=dim,
                                 x=x, z=z, zoom=cur_zoom)
                try:
                    await cdp(ws, state, "Page.navigate", {"url": url})
                except websockets.ConnectionClosed:
                    break  # window closed mid-tick
                print(f"  → {DIM_LABEL.get(dim, dim)} {x}, {z}  (zoom {cur_zoom})")
    except (KeyboardInterrupt, asyncio.CancelledError):
        pass
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
        shutil.rmtree(profile, ignore_errors=True)
        print("follow-map: stopped")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--mc-tui", required=True, help="path to the mc-tui script")
    p.add_argument("--player", required=True)
    p.add_argument("--seed", required=True)
    p.add_argument("--platform", default="java_26_1")
    p.add_argument("--interval", type=float, default=10.0)
    p.add_argument("--zoom", default="2")
    args = p.parse_args()
    try:
        asyncio.run(run(args))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
