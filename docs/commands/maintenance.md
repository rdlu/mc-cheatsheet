# Server maintenance

The RCON favorites — see [Server management](../server.md) for the full
mcrcon setup and backup workflow.

| Command | Effect |
| --- | --- |
| `save-all` | flush world to disk |
| `save-off` / `save-on` | pause autosave (do this around backups) |
| `stop` | graceful shutdown |
| `help` / `help tp` | list commands / usage of one |

## Backup sequence

```text
save-off
save-all flush
# ... copy the world directory (tar/rsync) ...
save-on
```

`save-all flush` blocks until everything is written — safer than plain
`save-all` before a copy.

!!! warning
    Never copy the world directory while autosave is on — you can catch
    region files mid-write and corrupt the backup.
