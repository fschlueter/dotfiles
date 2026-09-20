# AeroSpace session save/restore

Scripts and a background agent that remember which window lives in which
workspace, so a restart of AeroSpace (or a reboot) doesn't collapse your whole
layout onto a single workspace.

## Why this exists

AeroSpace does not persist window→workspace layout across restarts. When
AeroSpace restarts, macOS moves every window onto one Space, so all your
carefully-arranged windows end up piled together. These scripts snapshot the
layout and put windows back.

> Tip: most config changes do **not** require a full restart. Use
> `aerospace reload-config` (or just save `aerospace.toml`, since
> `auto-reload-config = true`). A full restart is what scatters windows, so
> avoid it when you can.

## Files

| File | Purpose |
|------|---------|
| `save-session.sh` | Snapshots current windows to `session.tsv`. |
| `restore-session.sh` | Reads `session.tsv` and moves windows back to their workspaces. |
| `session.tsv` | The saved layout: `workspace<TAB>app-name<TAB>window-title`, one line per window. |
| `~/Library/LaunchAgents/com.felix.aerospace.session-save.plist` | LaunchAgent that runs `save-session.sh` periodically. |

## How it works

- **Save** dumps every window as `workspace | app-name | window-title`.
  It refuses to save if the layout looks *collapsed* (≥4 windows all on one
  workspace), so it won't overwrite a good session right after a restart, before
  restore has run.
- **Restore** matches each saved entry to a currently-open window by
  **app name + window title** (window IDs change across restarts, so they can't
  be used). If the exact title isn't found, it falls back to matching by app
  name only. Already-placed windows are tracked so duplicate windows (e.g. two
  identical terminal windows) don't fight over the same slot.

## Automatic behaviour

- **On AeroSpace startup:** `after-startup-command` in `aerospace.toml` runs
  `restore-session.sh`.
- **Periodic save:** the LaunchAgent runs `save-session.sh` every 60 seconds
  (see below), keeping `session.tsv` fresh without manual effort.

## Manual keybindings

Defined in `aerospace.toml`:

- `alt-shift-comma` — save session now
- `alt-shift-period` — restore session now

Run one manually before an intentional restart to capture your latest layout.

## The background agent (LaunchAgent)

The periodic saver is a user LaunchAgent:
`~/Library/LaunchAgents/com.felix.aerospace.session-save.plist`.

### Load / unload

```sh
# enable
launchctl load ~/Library/LaunchAgents/com.felix.aerospace.session-save.plist

# disable
launchctl unload ~/Library/LaunchAgents/com.felix.aerospace.session-save.plist

# check it's registered
launchctl list | grep aerospace
```

### Logs

- stdout: `/tmp/aerospace-session-save.log`
- stderr: `/tmp/aerospace-session-save.err`

### Is running every 60s a lot? (No.)

It's negligible. Each run only issues a quick `aerospace list-windows` query to
the already-running AeroSpace server plus a little text processing — it finishes
in milliseconds and is completely idle the rest of the minute. `launchd` wakes
it once a minute; it is **not** a busy loop. No meaningful CPU or battery cost.

The only trade-off of the interval is *staleness*: if you rearrange windows and
restart within the same minute, the last change may not be captured. To reduce
that, either hit `alt-shift-comma` before restarting, or lower the interval.

### Changing the interval

Edit the `StartInterval` value (seconds) in the plist, then reload:

```sh
# e.g. change to every 5 minutes
# StartInterval -> 300
launchctl unload ~/Library/LaunchAgents/com.felix.aerospace.session-save.plist
launchctl load   ~/Library/LaunchAgents/com.felix.aerospace.session-save.plist
```

## Environment variables

Both scripts honour these:

- `AEROSPACE_SESSION_FILE` — path to the session file
  (default `~/.config/aerospace/session.tsv`).
- `AEROSPACE_RESTORE_DELAY` — seconds `restore-session.sh` waits before running,
  to give apps time to open their windows after login (default `2`).

## Caveats

- **Apps must be open** for their windows to be placed. After a reboot, add the
  apps you care about to macOS Login Items, or restore will report them as
  "not found". Increase `AEROSPACE_RESTORE_DELAY` on slower machines.
- **Title-based matching** is imperfect for apps whose titles change often
  (browsers, editors). The app-only fallback handles the common "one window per
  app" case, but distribution across many windows of the same app may not be
  exact.
- For apps that always belong on a fixed workspace, consider
  `on-window-detected` rules in `aerospace.toml` instead — that's more robust
  than session restore for those.
