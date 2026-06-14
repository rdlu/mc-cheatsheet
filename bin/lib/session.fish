# --- terminal session: TUI + RCON console side by side ----------------------------
# `mc-tui session [tmux|zellij]` — session "craftops", one window/tab with
# mc-tui, another with the RCON console. No argument: tmux if installed,
# else zellij.

function term_session --argument-names mux
    set -l s craftops
    if test -z "$mux"
        if type -q tmux
            set mux tmux
        else
            set mux zellij
        end
    end
    switch $mux
    case tmux
        type -q tmux; or _die 'tmux is not installed'
        if not tmux has-session -t $s 2>/dev/null
            tmux new-session -d -s $s -n tui $SELF
            tmux new-window -t $s -n rcon "$SELF console"
            tmux select-window -t "$s:tui"
        end
        if set -q TMUX
            tmux switch-client -t $s
        else
            tmux attach -t $s
        end
    case zellij
        type -q zellij; or _die 'zellij is not installed'
        set -q ZELLIJ; and _die 'already inside zellij — detach first (Ctrl-o d)'
        if zellij list-sessions -s 2>/dev/null | grep -qx $s
            zellij attach $s
        else
            set -l layout (mktemp /tmp/mc-tui-layout.XXXXXX.kdl)
            echo 'layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
    tab name="tui" {
        pane command="@SELF@"
    }
    tab name="rcon" {
        pane command="@SELF@" {
            args "console"
        }
    }
}' | string replace -a '@SELF@' $SELF >$layout
            zellij --session $s --new-session-with-layout $layout
        end
    case '*'
        _die "unknown multiplexer: $mux (use tmux or zellij)"
    end
end

