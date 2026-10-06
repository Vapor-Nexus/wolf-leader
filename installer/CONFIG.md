# Installer answer file — `wolf-leader-setup.ini`

The Windows and Mac installers both read this file. The user's own AI agent writes it in response to
`PROMPT.md`; the user pastes it into (or loads it from) the installer. Passwords are **never** put in
this file by the agent: shares that need one say `password=ASK`, and the installer prompts the user
directly on a password page.

Format: plain INI. One `key=value` per line. No quotes. No inline comments. Unknown keys are ignored.
Every value below has a closed set of allowed answers or a strict shape; installers must reject a file
that violates them and show the offending line.

```ini
[wolf]
; version of this format; installers refuse anything else
format=1
; which OS the agent inspected: windows | mac
os=windows
; hub location the client should talk to. For mode=new on this machine use http://localhost:6971
hub_url=http://wolf.local:6971
mcp_url=http://wolf.local:6972/mcp
; IANA zone for human-facing times, e.g. America/Chicago
timezone=America/Chicago
; short machine label shown on the hub, [A-Za-z0-9-]{1,32}
device_name=DESKTOP-1234

[detected]
; what is already installed on this machine: yes | no  (agent checks, does not guess)
git=yes
python=yes
python_version=3.13.1
docker=no
obsidian=no
cursor=yes
claude_code=no
; existing Wolf Leader client files in ~/.cursor (skills/save or rules/wolf-leader-hub.mdc): yes | no
wolf_client=no

[backup]
; the agent backs up configs BEFORE answering (see PROMPT.md): yes | no
done=yes
; absolute path of that folder, or NONE when done=no
path=C:\Users\me\WolfLeader-backup-20261006-1240
; digits only
files=23

[share1]
; up to five sections: share1..share5. Omit all of them if no network share is used.
; windows form, e.g. \\server\share   (required when os=windows)
unc=\\wolf.local\wolf
; mac form, e.g. smb://server/share   (required when os=mac)
smb_url=smb://wolf.local/wolf
; Windows drive letter A-Z, single letter, no colon (windows only)
letter=W
; username for the share, or NONE for guest access
user=wolf
; ASK = installer prompts for it | NONE = no password
password=ASK
; role of this share: wolf (the Wolf Leader drive: repos, vault, git remotes) | extra
role=wolf
```

## Installer-only fields (not from the agent)

Collected on installer pages and merged in memory before install; never written back to disk:

| Field | Page | Notes |
|---|---|---|
| `mode` | page 1 | `new` (host a hub here, needs Docker) · `connect` (use an existing hub) · `update` (refresh client files on a PC that already has WL) |
| toggles | page 2 | `client` (skills + rule + MCP for Cursor / Claude Code), `shares` (map the shares), `prereqs` (install Git + Python if missing), `obsidian` (install Obsidian — **recommended**), `wiki` (build the Fumadocs wiki on a new hub — **highly recommended**; only shown when mode=new) |
| `git_name`, `git_email` | git identity page | real or made-up; set with `git config --global` so local commits never stall on GitHub auth |
| share passwords | password page | one masked field per share with `password=ASK`; stored with `cmdkey` (Windows) or the login Keychain (Mac) |

## Save state before install (always, first)

- The agent's backup is reported in `[backup]`. If `done=no`, or `path` doesn't exist, the installer
  says so on the ready page.
- Either way, the installer snapshots every file it is about to create or overwrite (`~/.cursor/mcp.json`,
  `rules/wolf-leader-hub.mdc`, `skills/{save,new,wolfhowl,wolfeat}`, `AGENTS.md`, `wolf-leader.env`,
  `~/.claude/skills/{...}`, `~/.gitconfig`, hub `.env`) into
  `%LOCALAPPDATA%\WolfLeader\backup-<YYYYMMDD-HHMM>` (Windows) or
  `~/Library/Application Support/WolfLeader/backup-<YYYYMMDD-HHMM>` (Mac), and writes `restore.ps1` /
  `restore.sh` there that copies them back. The finish page shows that path.

## Mode labels

`new` is shown as **"New hub on this computer — Docker (experimental)"** with the note: "The hub runs in
Docker. An always-on box (NAS, Proxmox LXC, Linux server) is the tested setup; a hub on your desktop
works but is experimental." `connect` is the recommended choice when a hub already exists.

## What install does, by toggle

- **prereqs** — Windows: `winget install Git.Git`, `Python.Python.3.13`. Mac: Xcode CLT for git, `brew install python@3.13` if Homebrew exists, else open python.org.
- **shares** — Windows: `cmdkey /add` + `net use <letter>: <unc> /persistent:yes`. Mac: Keychain entry + `open smb://...`, add to Login Items. Then `git config --global --add safe.directory '*'`.
- **client** — copy `examples/cursor/{skills,rules}` and `examples/AGENTS.md` into `~/.cursor`, merge `wolf-leader` into `~/.cursor/mcp.json`, write `~/.cursor/wolf-leader.env` (`WOLF_LEADER_API`, `WOLF_LEADER_MCP`). Same skills into `~/.claude/skills` when `claude_code=yes`. **No hooks.**
- **obsidian** — Windows: `winget install Obsidian.Obsidian`. Mac: `brew install --cask obsidian` or download page. Point the user at `<wolf share>\wolf-leader\vault`.
- **mode=new** — requires Docker. Write `.env` from `.env.example` (`IDE_STORAGE_PUBLIC_URL`, `WOLF_TZ`, `WOLF_WIKI_ENABLED=1|0`, `WOLF_SHARE_ROOT`), then `docker compose -f docker-compose.postgres.yml up -d --build`, wait for `/health`.
- Always: `git config --global user.name/user.email` from the identity page; verify `GET <hub_url>/health`.
