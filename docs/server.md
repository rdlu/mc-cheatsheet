# Server management

Managing the server over **RCON** with
[`mcrcon`](https://github.com/Tiiffi/mcrcon) (AUR: `mcrcon`).
All commands on this site are written without the leading `/` because
that's how the server console and RCON expect them.

## RCON setup (`server.properties`)

```properties
enable-rcon=true
rcon.port=25575
rcon.password=choose-a-long-random-password
```

Restart the server after changing these.

!!! danger "RCON is plaintext"
    The RCON protocol sends the password and every command **unencrypted**.
    Only use it on `localhost` or a trusted LAN — never expose
    `rcon.port` to the internet. For remote admin, tunnel over SSH:

    ```sh
    ssh -L 25575:localhost:25575 mc-server-host
    # then point mcrcon at localhost as usual
    ```

## mcrcon usage

Interactive terminal session (the usual way in):

```sh
mcrcon -H localhost -P 25575 -p "$MCRCON_PASS" -t
```

mcrcon also reads its connection from the environment, so with
`MCRCON_HOST` / `MCRCON_PORT` / `MCRCON_PASS` set it's just:

```fish
# fish — put the password somewhere private, not in config.fish committed to dotfiles
set -gx MCRCON_HOST localhost
set -gx MCRCON_PORT 25575
set -gx MCRCON_PASS (cat ~/.config/mcrcon/pass)

mcrcon -t        # interactive: type commands, Ctrl-D or "Q" to quit
```

One-shot commands (scriptable — each argument is a command):

```sh
mcrcon "say Backup starting" save-off "save-all flush"
```

!!! tip "nmcrcon for interactive sessions"
    [`nmcrcon`](https://github.com/nicholascw/nmcrcon) (AUR:
    `nmcrcon-git`) is a nicer interactive console: arrow keys, Ctrl-R
    history search, persistent history, a masked password prompt, and —
    unlike the unmaintained mcrcon 0.7.2 — it handles responses larger
    than one packet (mcrcon's classic *"Invalid packet size"* crash on
    long `help` or `data get` output). It reads the same `MCRCON_*`
    environment variables. **Keep mcrcon for scripts**, though:
    nmcrcon has no one-shot command mode yet, no silent mode, and
    always exits 0. mc-tui does exactly this split — `[console]` opens
    nmcrcon when installed, while run-command stays on mcrcon.

## mc-tui — the cheatsheet as a TUI

[`bin/mc-tui`](https://github.com/rdlu/mc-cheatsheet/blob/main/bin/mc-tui)
(fish + fzf, run it with `mise run tui`) wraps every command on this site
in an interactive picker:

- **Browse by category** — the same commands as the
  [Commands](commands/selectors.md) pages, plus the full god-gear set.
- **Placeholders are filled interactively** — `<player>` offers your saved
  player names and selectors, `<item>` searches ~200 useful items
  (gear, food, potions, enchanted books, redstone, …), `<enchantment>`,
  `<effect>`, `<entity>`, `<structure>` and `<biome>` get their own pickers,
  anything else is a quick prompt. Optional slots (like `<count?>`) can be
  skipped with enter.
- **Searchable in English *and* português (pt-BR)** — the item, enchantment,
  effect, entity and biome pickers carry the official Brazilian Portuguese
  names from the game's language file, so typing `picareta`, `fogueira` or
  `remendo` finds the right id.
- **Copy or run** — the finished command goes to the clipboard
  (`wl-copy`/`xclip`) and/or straight to the server over RCON via `mcrcon`.
- **`[settings]`** stores host / port / password in
  `~/.config/mc-tui/rcon.conf` (`chmod 600` — remember,
  [RCON is plaintext](#rcon-setup-serverproperties)).
- **`[players]`** keeps a name list for `<player>` slots — `ctrl-f`
  fetches whoever is online right now (via `list` over RCON), `ctrl-a`
  adds names manually.
- **`[console]`** drops into an interactive session — `nmcrcon` when
  installed (better line editing + history), else `mcrcon -t`.

Subcommands reuse the saved settings outside the picker:

| Command | Use |
| --- | --- |
| `mise run console` (`mc-tui console`) | interactive RCON console |
| `mc-tui run save-all flush` | one-shot command, for scripts and backups |
| `mise run session` (`mc-tui session`) | tmux (or zellij) session `craftops` — TUI in one window, console in the other, copy with ++ctrl+y++ and paste across |

The command and item tables are plain pipe-delimited text — inspect them
with `mc-tui __dump catalog` (or `items`, `enchantments`, `effects`, …)
and add your own rows in `~/.config/mc-tui/catalog.local` and
`items.local` using the same `category|template|description` format.

!!! tip "No terminal?"
    The [Command builder](builder.md) is the same picker as a web page —
    same catalog, same bilingual item search, copy-paste into the game
    chat. Works on phones; share it with whoever plays on the server.

## Backup flow

Autosave **must** be paused while copying the world, or region files can be
caught mid-write:

```sh
mcrcon save-off "save-all flush"
tar -C /path/to/server -czf "backup-$(date -I).tar.gz" world
mcrcon save-on "say Backup done"
```

- `save-all flush` blocks until the world is fully written to disk.
- If the backup script dies between `save-off` and `save-on`, autosave
  stays off — make the script `trap`-safe or check with `save-on`
  after any failed run.
- Test restores occasionally; a backup that's never been restored is a hope,
  not a backup.

## Day-to-day favorites

| Command | Use |
| --- | --- |
| `list` | who's online |
| `say <msg>` | warn before restarts |
| `whitelist add <player>` | onboard a friend |
| `stop` | graceful shutdown (saves first) |

See [Commands → Server maintenance](commands/maintenance.md) for the full
table, and the rest of the [Commands](commands/selectors.md) section for
everything else.
