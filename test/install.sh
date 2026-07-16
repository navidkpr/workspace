#!/usr/bin/env bash

set -euo pipefail

repository_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

export HOME="$test_root/home"
export XDG_CONFIG_HOME="$HOME/.config"
export WS_SKIP_GHOSTTY=1
export WS_SKIP_TMUX_RELOAD=1
mkdir -p "$HOME"

"$repository_dir/install.sh"
"$repository_dir/install.sh"

test -x "$HOME/.local/bin/ws"
test -f "$HOME/.zsh/completions/_ws"
test -f "$HOME/.config/ws/config.json"
test -f "$HOME/.config/ws/tmux.conf"
test -f "$HOME/.config/ws/ghostty.conf"
grep -Fq '"paneLayout": "1x3"' "$HOME/.config/ws/config.json"
grep -Fq '"reviewMode": "cursor"' "$HOME/.config/ws/config.json"
grep -Fq 'keybind = alt+r=set_tab_title:__WS_TOGGLE_ATTENTION__' "$HOME/.config/ws/ghostty.conf"
grep -Fq 'keybind = alt+q=set_tab_title:__WS_REVIEW_WORKSPACE__' "$HOME/.config/ws/ghostty.conf"
grep -Fq 'keybind = alt+f=set_tab_title:__WS_FORK_CURRENT_SESSION__' "$HOME/.config/ws/ghostty.conf"
! grep -A1 -F 'keybind = alt+r=' "$HOME/.config/ws/ghostty.conf" | tail -1 | grep -Fq 'chain='
test "$(grep -Fc '# workspace completion' "$HOME/.zshrc")" -eq 1
! grep -Fq '@WS_BIN@' "$HOME/.config/ws/tmux.conf"
grep -Fq "$HOME/.local/bin/ws" "$HOME/.config/ws/tmux.conf"
grep -Fq "xterm-ghostty:extkeys:hyperlinks" "$HOME/.config/ws/tmux.conf"
"$HOME/.local/bin/ws" help >/dev/null

printf 'install test passed\n'
