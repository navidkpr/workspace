# Workspace

Fast, persistent Codex workspaces for Ghostty.

`ws` turns Git worktrees and Codex sessions into one compact workflow. Each workspace gets its own branch and directory, Codex conversations survive closed tabs through tmux, and Ghostty tabs stay grouped with live working and unread indicators.

```text
ws  ⠙1    delivery    delivery  🔵1    trace_visibility
    └─ working             └─ needs attention
```

## What it does

- Creates isolated `codex/<name>` Git worktrees.
- Restores every non-archived Codex conversation for a workspace.
- Keeps Codex running after a Ghostty tab closes.
- Packs conversations into configurable pane layouts.
- Groups tabs belonging to the same workspace.
- Shows live working and unread state in tab titles.
- Pins important conversations with a persistent in-pane marker.
- Archives Codex conversations when a workspace is removed.
- Supports native Zsh completion and short command aliases.

## Requirements

- macOS
- [Ghostty](https://ghostty.org/) 1.3 or newer
- [Codex CLI](https://developers.openai.com/codex/cli/)
- Node.js 20 or newer
- Git
- [Delta](https://dandavison.github.io/delta/) for the default diff viewer
- tmux
- Zsh for shell completion
- `fzf` for the optional interactive picker

Cursor, lazygit, and GitHub CLI are optional review backends.

## Install

```bash
git clone https://github.com/navidkpr/workspace.git
cd workspace
./install.sh
```

Restart your shell after the first install. Ghostty configuration is reloaded automatically when Ghostty is running.

The installer writes:

```text
~/.local/bin/ws
~/.zsh/completions/_ws
~/.config/ws/config.json
~/.config/ws/tmux.conf
~/.config/ws/ghostty.conf
```

It also adds one `config-file` include to Ghostty and a small completion block to `~/.zshrc`.

## Quick start

Run these commands from any checkout in a Git repository:

```bash
ws new costs
ws ls
ws open costs
ws remove costs
```

Worktrees are stored under:

```text
~/Worktrees/codex/<repository>/<workspace>
```

Override the root with `CODEX_WS_ROOT`.

## Commands

| Command | Alias | Description |
| --- | --- | --- |
| `ws` | | Open the searchable workspace picker. |
| `ws new <name>` | `ws ne` | Create a worktree and start Codex. |
| `ws open <name>` | `ws op` | Restore the workspace's Codex sessions. |
| `ws repair` | | Reconcile the current workspace's pane layout. |
| `ws repair --all` | | Repair every workspace tab in the current Ghostty window. |
| `ws review <name>` | `ws rv` | Review a workspace using Delta, lazygit, Cursor, or GitHub. |
| `ws remove <name>` | `ws rm` | Archive sessions and remove the worktree and branch. |
| `ws list` | `ws ls` | Show workspaces, activity, Git state, chats, and latest topic. |
| `ws sessions <name>` | | List a workspace's Codex sessions. |
| `ws cp session <id>` | | Copy a Codex session into the current workspace. |
| `ws mv session <id>` | | Move a Codex session into the current workspace. |
| `ws name <id> <name>` | | Give a Codex session a persistent display name. |
| `ws pin <id>` | | Pin a Codex session. |
| `ws unpin <id>` | | Unpin a Codex session. |
| `ws pins` | | List pinned Codex sessions. |
| `ws path <name>` | | Print a workspace path. |
| `ws config` | `ws cfg` | Edit settings with `$VISUAL`, `$EDITOR`, or Vim. |

Use `.` anywhere a workspace name is accepted to target the current checkout.

## Ghostty shortcuts

| Shortcut | Action |
| --- | --- |
| `Option+F` | Fork without interrupting the current conversation; the child composer is prefilled with a handoff. |
| `Option+N` | Start a fresh Codex conversation using the layout policy. |
| `Option+W` | Archive the current conversation and close its pane; pinned chats require confirmation. |
| `Option+R` | Toggle the current conversation between read and unread. |
| `Option+J` | Review the current workspace using the configured review mode. |
| `Option+Shift+J` | Review only the focused conversation's latest finished turn. |
| `Option+K` | Name the current conversation. |
| `Option+P` | Pin or unpin the current conversation. |
| `Option+Enter` | Insert a newline in the Codex composer. |

Clicking an unread pane marks it read. A thin Braille spinner means Codex is working; a blue circle means a conversation needs attention. Tabs with the same workspace are kept adjacent.

Option+Shift+J reads the focused conversation's own latest finished turn from Codex and renders only its recorded file changes in Delta, so concurrent panes in the same worktree do not get mixed together.

Named conversations show their name in the right-aligned pane footer. Pinned conversations open first, use a muted amber footer, show `📌 pinned` beside the name, and contribute a `📌N` count to the tab title. Names and pins survive reopen, repair, copy, and move.

## Configuration

Run `ws config` or edit `~/.config/ws/config.json`:

```json
{
  "openMode": "tabs",
  "paneLayout": "1x3",
  "reviewMode": "delta",
  "sessionBackend": "tmux"
}
```

### Open modes

- `tabs` adds workspace tabs to the current Ghostty window.
- `window` creates a dedicated Ghostty window.

Override the configured mode per invocation with `--tabs` or `--window`.

### Pane layouts

| Value | Layout |
| --- | --- |
| `1x1` | One conversation per tab. |
| `1x2` | Two side-by-side conversations: `A \| B`. |
| `1x3` | Three side-by-side conversations: `A \| B \| C`. Default. |
| `2x1` | Two stacked conversations. |
| `2x2` | Fill `1 → 1\|1 → 2\|1 → 2\|2`, then create another tab. |

### Session backends

- `tmux` keeps Codex alive when its Ghostty surface closes.
- `direct` runs Codex directly in Ghostty.

### Review modes

- `delta` opens a clean, read-only, side-by-side diff in Ghostty. This is the default.
- `cursor` opens the worktree in a classic Cursor IDE window with native diffs for its changes.
- `lazygit` opens or focuses a review tab beside the workspace.
- `github` opens the current branch's pull request, falling back to a compare/diff page.

Override the configured mode for one invocation:

```bash
ws review . --mode delta
ws review costs --mode github
```

## Repair behavior

Repair is deliberately conservative:

- Compatible panes stay where they are.
- Unrelated panes are never removed.
- Review tabs are left untouched.
- Visible panes are equalized after creation and repair.
- Missing Codex sessions are restored.
- Misplaced Codex panes are restarted only when required by the selected layout.
- `ws repair --all` is scoped to the current Ghostty window.

Preview changes safely:

```bash
ws repair --all --dry-run
```

## Removing a workspace

`ws remove <name>` archives its Codex sessions before deleting the worktree and `codex/<name>` branch. It refuses to remove dirty worktrees or active sessions unless `--force` is supplied.

```bash
ws rm costs
ws rm costs --force
ws rm costs --keep-branch
```

## How it works

`ws` is a dependency-free Node.js CLI. It combines:

- `git worktree` for isolated branches and checkouts
- the Codex app-server for session discovery, copying, moving, and archiving
- tmux for persistent Codex processes
- Ghostty's AppleScript and terminal APIs for tabs, panes, focus, titles, and layout

The background title daemon observes Ghostty terminal titles, focus, and tmux pane state every 250 ms while workspace tabs are visible. It supports both direct and tmux-backed Codex sessions and owns only tab grouping, status titles, and unread-pane tinting.

## Development

```bash
node --check bin/ws
bash -n install.sh
./test/install.sh
```

The project has no runtime package dependencies.

## License

MIT
