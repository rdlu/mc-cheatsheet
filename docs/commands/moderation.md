# Chat & moderation

## Chat & players

| Command | Effect |
| --- | --- |
| `list` | who's online (great over RCON) |
| `say Server restarting soon` | broadcast to all |
| `msg Alice dinner time` | private message |
| `kick Alice afk too long` | reason is optional |

Formatted broadcast with `tellraw`:

```text
tellraw @a {"text":"Hello","color":"gold","bold":true}
```

Useful `tellraw` colors: `gold`, `red`, `green`, `aqua`, `yellow`,
`light_purple`, or any `"#RRGGBB"` hex.

## Moderation

| Command | Effect |
| --- | --- |
| `op Alice` / `deop Alice` | grant / revoke operator |
| `whitelist add Alice` | also: `remove`, `list`, `reload` |
| `whitelist on` | enforce the whitelist |
| `ban Alice griefing` | `pardon Alice` to undo |
| `ban-ip 1.2.3.4` | `pardon-ip` to undo |
| `banlist` | show bans |

!!! tip "Whitelist over bans"
    For a friends-only server, `whitelist on` + `whitelist add` for each
    player beats reactive banning — nobody unknown ever joins.
