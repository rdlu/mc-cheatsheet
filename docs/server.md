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
