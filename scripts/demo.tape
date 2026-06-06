# vhs tape for the mc-tui demo GIF — https://github.com/charmbracelet/vhs
# Regenerate with `mise run demo` (needs vhs + ttyd + ffmpeg installed).
#
# Shows the offline-safe flow: browse a category, pick a command, fill the
# <player>/<item> placeholders from pickers — including the Brazilian
# Portuguese item search (type "picareta" to find the pickaxes by their pt-BR
# names) — and land on the built command. No RCON or browser involved.

Output docs/img/mc-tui.gif

Require fish
Require bin/mc-tui

Set Shell fish
Set FontSize 15
Set Width 1200
Set Height 720
Set Padding 16
Set Theme "Catppuccin Mocha"
Set Framerate 24

# hidden setup so the recording opens on a clean prompt
Hide
Type "cd /home/rdlu/Projects/mc-cheatsheet" Enter
Type "clear" Enter
Show

Sleep 600ms
Type "bin/mc-tui" Sleep 400ms Enter
Sleep 2.5s

# main menu: filter to the "give & items" category
Type "give" Sleep 1.2s
Enter
Sleep 1.5s

# pick the give-with-count command
Type "count" Sleep 1s
Enter
Sleep 1.3s

# <player>: type a name (selectors + saved names are offered too)
Type "Steve" Sleep 1s
Enter
Sleep 1.3s

# <item>: search in Portuguese — "picareta" finds netherite_pickaxe
Type "picareta" Sleep 1.8s
Enter
Sleep 1.3s

# <count?>: pick a common stack size (64 is highlighted) — or type one, esc skips
Sleep 1.3s
Enter
Sleep 1.2s

# action menu shows the finished command (give Steve <pickaxe>) with the
# copy / run-over-RCON options
Sleep 3s

# back out and quit
Escape Sleep 700ms
Escape Sleep 500ms
Escape
Sleep 1.2s
