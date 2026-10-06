# Prompt the installer shows (copy → paste into your AI agent)

Installers render this text with `{{OS}}` replaced by `windows` or `mac`, `{{MODE}}` by `new`,
`connect` or `update`, and `{{HUB_HINT}}` by `http://localhost:6971` for `new`, otherwise
`http://wolf.local:6971`. Keep the wording: it is written to force exact, machine-readable answers.

---

You are helping me install **Wolf Leader**, a self-hosted memory hub for AI coding agents. Inspect
**this computer** and reply with **one INI code block and nothing else**. The installer will parse it
with a strict parser, so follow these rules exactly:

1. Output exactly one fenced code block tagged `ini`. No prose before or after it.
2. Use only the keys listed below. One `key=value` per line. No quotes, no comments, no blank values.
3. Every value must be one of the allowed answers shown. If you cannot verify something by running a
   command, answer `no` (for yes/no keys) — never guess `yes`.
4. Never write a password. For a share that needs one, write `password=ASK`. For guest access write
   `user=NONE` and `password=NONE`.
5. Run real commands to check. Use: `git --version`, `python --version` (or `python3 --version`),
   `docker --version`, and look for Obsidian, Cursor and Claude Code in the usual install locations.
   On Windows use `net use` to list mapped shares; on a Mac use `mount | grep smbfs`.

**Before you answer, back this machine up.** Create the folder
`~/WolfLeader-backup-<YYYYMMDD-HHMM>` (on Windows `%USERPROFILE%\WolfLeader-backup-<YYYYMMDD-HHMM>`) and
copy into it every one of these that exists, keeping the folder structure:
`~/.cursor/mcp.json`, `~/.cursor/hooks.json`, `~/.cursor/AGENTS.md`, `~/.cursor/wolf-leader.env`,
`~/.cursor/rules/`, `~/.cursor/skills/`, `~/.claude/settings.json`, `~/.claude/CLAUDE.md`,
`~/.claude/skills/`, `~/.gitconfig`, and the `.env` of any existing Wolf Leader hub folder.
Also save the output of `net use` (Windows) or `mount | grep smbfs` (Mac) to `shares.txt` in that
folder. Never copy passwords or keychain data. Report the folder in the `[backup]` section; if you
could not make the backup, write `done=no` and the installer will make one itself.

This machine's OS is `{{OS}}`. Install mode is `{{MODE}}`.

```ini
[wolf]
format=1
os={{OS}}
hub_url=<URL of the Wolf Leader hub REST API. If unknown write {{HUB_HINT}}>
mcp_url=<same host as hub_url, port 6972, path /mcp>
timezone=<this machine's IANA time zone, e.g. America/Chicago>
device_name=<this machine's hostname, letters/digits/hyphens only, max 32 chars>

[detected]
git=<yes|no>
python=<yes|no>
python_version=<exact version like 3.13.1, or NONE>
docker=<yes|no>
obsidian=<yes|no>
cursor=<yes|no>
claude_code=<yes|no>
wolf_client=<yes if ~/.cursor/skills/save or ~/.cursor/rules/wolf-leader-hub.mdc exists, else no>

[backup]
done=<yes|no>
path=<absolute path of the backup folder you created, or NONE>
files=<number of files you copied, digits only>

[share1]
unc=<Windows only: \\server\share, else NONE>
smb_url=<Mac only: smb://server/share, else NONE>
letter=<Windows only: single drive letter A-Z without colon, else NONE>
user=<share username, or NONE>
password=<ASK or NONE>
role=<wolf for the drive that holds Wolf Leader projects and vault, else extra>
```

Add `[share2]` … `[share5]` with the same keys for every other network share this machine already
maps that I use for projects. If this machine maps no network shares, omit all `[shareN]` sections.

---

## Why it is shaped like this

- Closed answer sets (`yes|no`, `ASK|NONE`, single letters) leave nothing to interpret.
- "Answer `no` if you cannot verify" stops agents from optimistic guesses.
- Passwords stay out of AI chats entirely; the installer asks for them on its own masked page.
- One fenced block and nothing else means the installer can paste-parse without trimming prose.
