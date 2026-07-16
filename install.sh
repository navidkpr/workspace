#!/usr/bin/env bash

set -euo pipefail

repository_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="$HOME/.local/bin"
completion_dir="$HOME/.zsh/completions"
config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
config_dir="$config_root/ws"
ws_bin="$bin_dir/ws"

install -d "$bin_dir" "$completion_dir" "$config_dir"
install -m 755 "$repository_dir/bin/ws" "$ws_bin"
install -m 644 "$repository_dir/completions/_ws" "$completion_dir/_ws"

if [[ ! -f "$config_dir/config.json" ]]; then
  install -m 644 "$repository_dir/templates/config.json" "$config_dir/config.json"
fi

escaped_ws_bin=${ws_bin//|/\\|}
escaped_ws_bin=${escaped_ws_bin//&/\\&}
sed "s|@WS_BIN@|${escaped_ws_bin}|g" \
  "$repository_dir/templates/tmux.conf" >"$config_dir/tmux.conf"
install -m 644 "$repository_dir/templates/ghostty.conf" "$config_dir/ghostty.conf"

zshrc="$HOME/.zshrc"
completion_marker="# workspace completion"
if [[ ! -f "$zshrc" ]] || ! grep -Fq "$completion_marker" "$zshrc"; then
  {
    printf '\n%s\n' "$completion_marker"
    printf 'fpath=("$HOME/.zsh/completions" $fpath)\n'
    printf 'autoload -Uz compinit && compinit\n'
  } >>"$zshrc"
fi

if [[ "${WS_SKIP_GHOSTTY:-0}" != "1" ]]; then
  ghostty_config="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
  install -d "$(dirname -- "$ghostty_config")"
  touch "$ghostty_config"
  include_line="config-file = \"$config_dir/ghostty.conf\""
  if ! grep -Fqx "$include_line" "$ghostty_config"; then
    printf '\n# workspace\n%s\n' "$include_line" >>"$ghostty_config"
  fi

  ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"
  if [[ -x "$ghostty_bin" ]]; then
    "$ghostty_bin" +validate-config
    osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
using terms from application "Ghostty"
  tell application "Ghostty"
    if (count of windows) > 0 then
      set candidateWindow to front window
      set candidateTab to selected tab of candidateWindow
      perform action "reload_config" on focused terminal of candidateTab
    end if
  end tell
end using terms from
APPLESCRIPT
  fi
fi

if [[ "${WS_SKIP_TMUX_RELOAD:-0}" != "1" ]] && command -v tmux >/dev/null 2>&1; then
  tmux -L codex-ws source-file "$config_dir/tmux.conf" >/dev/null 2>&1 || true
fi

printf 'Installed ws to %s\n' "$ws_bin"
printf 'Run: ws help\n'
