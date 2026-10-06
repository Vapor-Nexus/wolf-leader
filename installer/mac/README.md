# Wolf Leader Setup for macOS

A guided installer built from native macOS dialogs. Same pages and answer file as the Windows
installer (contract: [`../CONFIG.md`](../CONFIG.md), [`../PROMPT.md`](../PROMPT.md)).

## Run it

- **From a clone:** double-click `start.command` in the repo root.
- **From a .dmg:** open `Wolf Leader Setup.app`.

The first time, macOS blocks apps and scripts from unidentified developers:

- macOS 14 or older: right-click > **Open** > **Open**.
- macOS 15 or newer: double-click once, then **System Settings > Privacy & Security > Open Anyway**.
- A `.command` that "cannot be executed" lost its execute bit: `chmod +x start.command`.

## Files

| File | What it does |
|---|---|
| `Wolf Leader Setup.command` | Double-click entry; runs `wizard.sh` in Terminal |
| `wizard.sh` | Dialogs: welcome, mode, options, ask your AI agent, share passwords, git identity, summary, finish |
| `install.sh` | The work. Saves an undo point first, then does what the answer file and toggles say. `--dry-run` prints every action |
| `ini.sh` | Strict `wolf-leader-setup.ini` parser and validator (bash + awk, no python) |
| `build.sh` | On a Mac: builds `dist/Wolf Leader Setup.app` (osacompile) and `dist/WolfLeaderSetup-<ver>.dmg` |

Optional art in `installer/assets/` (`mac-icon.png`, `whatsnew-cards.png`, `dmg-background.png`)
is used when present.

## Undo

Before changing anything, `install.sh` copies every file it may touch to
`~/Library/Application Support/WolfLeader/backup-<YYYYMMDD-HHMM>/` and writes `restore.sh` there:

```bash
bash ~/Library/Application\ Support/WolfLeader/backup-*/restore.sh
```

Keychain entries, Login Items, installed apps and Docker containers are not undone by it.

## Logs

`~/Library/Logs/WolfLeader/install.log`. Share passwords never appear in it, on a command line,
or in any file except a mode-600 temp file that `install.sh` deletes as soon as it starts.

## Preview on any machine

```bash
HOME=/tmp/fakehome bash installer/mac/install.sh --ini wolf-leader-setup.ini --mode connect \
  --git-name "Test" --git-email test@example.com --dry-run
```
