#!/bin/bash
# Wolf Leader Setup for macOS: the guided wizard (native dialogs via osascript), then install.sh.
# Started by "Wolf Leader Setup.command" (Terminal) or by the Wolf Leader Setup.app applet.
# Pages match the Windows installer: welcome, mode, options, ask your AI agent, share passwords,
# git identity, summary, install, finish. Contract: installer/CONFIG.md + installer/PROMPT.md.
# Must stay bash 3.2 compatible; needs no python.

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
# shellcheck source=ini.sh
. "$SCRIPT_DIR/ini.sh"

# pbcopy/pbpaste and osascript argv need a UTF-8 locale; apps launched from Finder have none.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
PATH="/opt/homebrew/bin:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"
export PATH

TITLE="Wolf Leader Setup"
ASSETS="$ROOT/installer/assets"
LOG_DIR="$HOME/Library/Logs/WolfLeader"
LOG="$LOG_DIR/install.log"
mkdir -p "$LOG_DIR"

if [ "$(uname -s)" != Darwin ]; then
  echo "Wolf Leader Setup for Mac only runs on macOS." >&2
  exit 1
fi

umask 077
WORK=$(mktemp -d "${TMPDIR:-/tmp}/wolf-leader-setup.XXXXXX") || exit 1
trap 'rm -rf "$WORK"' EXIT

HAS_TTY=0
[ -t 1 ] && HAS_TTY=1
# From the .app there is no terminal: keep our own output in the install log.
[ "$HAS_TTY" = 1 ] || exec >>"$LOG" 2>&1

wlog() {
  printf '%s  wizard: %s\n' "$(date +%H:%M:%S)" "$*"
  [ "$HAS_TTY" = 1 ] && printf '%s  wizard: %s\n' "$(date +%H:%M:%S)" "$*" >>"$LOG"
  return 0
}

ICON=""
if [ -f "$ASSETS/mac-icon.icns" ]; then
  ICON="$ASSETS/mac-icon.icns"
elif [ -f "$ASSETS/mac-icon.png" ]; then
  if command -v sips >/dev/null 2>&1 \
    && sips -s format icns "$ASSETS/mac-icon.png" --out "$WORK/icon.icns" >/dev/null 2>&1; then
    ICON="$WORK/icon.icns"
  else
    ICON="$ASSETS/mac-icon.png"
  fi
fi

# --- dialog helpers ----------------------------------------------------------------------------
# All text goes in as argv (never spliced into AppleScript source), so quotes in values are safe.

# dlg "message" button... -> prints the button clicked ("Cancel" for Cancel/Esc). Last = default.
dlg() {
  osascript - "$TITLE" "$ICON" "$@" <<'AS' 2>/dev/null
on run argv
  set t to item 1 of argv
  set ic to item 2 of argv
  set m to item 3 of argv
  set b to items 4 thru -1 of argv
  activate
  try
    if ic is not "" then
      try
        set r to display dialog m with title t buttons b default button (count of b) with icon (POSIX file ic)
      on error number n
        if n is -128 then error number -128
        set r to display dialog m with title t buttons b default button (count of b) with icon note
      end try
    else
      set r to display dialog m with title t buttons b default button (count of b) with icon note
    end if
    return button returned of r
  on error number -128
    return "Cancel"
  end try
end run
AS
}

# dlg_input "message" "default" hidden(0|1) -> prints "OK:<text>" or "CANCEL"
dlg_input() {
  osascript - "$TITLE" "$ICON" "$@" <<'AS' 2>/dev/null
on run argv
  set t to item 1 of argv
  set ic to item 2 of argv
  set m to item 3 of argv
  set d to item 4 of argv
  set h to item 5 of argv
  activate
  try
    try
      if h is "1" then
        set r to display dialog m with title t default answer d buttons {"Cancel", "OK"} default button "OK" with icon (POSIX file ic) with hidden answer
      else
        set r to display dialog m with title t default answer d buttons {"Cancel", "OK"} default button "OK" with icon (POSIX file ic)
      end if
    on error number n
      if n is -128 then error number -128
      if h is "1" then
        set r to display dialog m with title t default answer d buttons {"Cancel", "OK"} default button "OK" with icon note with hidden answer
      else
        set r to display dialog m with title t default answer d buttons {"Cancel", "OK"} default button "OK" with icon note
      end if
    end try
    return "OK:" & (text returned of r)
  on error number -128
    return "CANCEL"
  end try
end run
AS
}

# dlg_list "prompt" multiple(0|1) "default1<LF>default2" item... -> "OK:<items, one per line>" or "CANCEL"
dlg_list() {
  osascript - "$TITLE" "$@" <<'AS' 2>/dev/null
on run argv
  set t to item 1 of argv
  set m to item 2 of argv
  set multi to item 3 of argv
  set defs to item 4 of argv
  set opts to items 5 thru -1 of argv
  set AppleScript's text item delimiters to linefeed
  set defList to {}
  if defs is not "" then set defList to text items of defs
  activate
  if multi is "1" then
    set r to choose from list opts with title t with prompt m default items defList OK button name "Next" cancel button name "Cancel" with multiple selections allowed and empty selection allowed
  else
    set r to choose from list opts with title t with prompt m default items defList OK button name "Next" cancel button name "Cancel"
  end if
  if r is false then return "CANCEL"
  return "OK:" & (r as text)
end run
AS
}

# dlg_file "prompt" -> "OK:/posix/path" or "CANCEL"
dlg_file() {
  osascript - "$@" <<'AS' 2>/dev/null
on run argv
  activate
  try
    set f to choose file with prompt (item 1 of argv) default location (path to downloads folder)
    return "OK:" & (POSIX path of f)
  on error number -128
    return "CANCEL"
  end try
end run
AS
}

notify() {
  osascript - "$TITLE" "$1" <<'AS' >/dev/null 2>&1
on run argv
  display notification (item 2 of argv) with title (item 1 of argv)
end run
AS
}

# Cancel anywhere: confirm, then quit (returns only if the user wants to go back).
confirm_quit() {
  local b
  b=$(dlg "Quit Wolf Leader Setup?

Nothing on this Mac has been changed yet." "Quit" "Go back")
  if [ "$b" = Quit ]; then
    wlog "user quit before installing"
    exit 0
  fi
}

has() { command -v "$1" >/dev/null 2>&1; }

git_usable() {
  local g
  g=$(command -v git 2>/dev/null) || return 1
  if [ "$g" = /usr/bin/git ]; then xcode-select -p >/dev/null 2>&1 || return 1; fi
  "$g" --version >/dev/null 2>&1
}

# --- pages --------------------------------------------------------------------------------------
L_NEW="New hub on this computer — Docker (experimental)"
L_CONNECT="Connect this Mac to an existing hub (recommended if you already have a hub)"
L_UPDATE="Update Wolf Leader files on this Mac"

T_CLIENT="Cursor / Claude Code client (skills + rule + MCP)"
T_SHARES="Map network shares"
T_PREREQS="Install Git + Python if missing"
T_OBSIDIAN="Install Obsidian — recommended"
T_WIKI="Build the wiki — highly recommended"

page_welcome() {
  local b
  while :; do
    if [ -f "$ASSETS/whatsnew-cards.png" ]; then
      b=$(dlg "Hey 👋  Wolf Leader v1 gave every agent you use one shared memory. This update builds on it: chats save themselves, every project is one question away in any new chat, and you can pick up on any machine." "See what's new" "Continue")
    else
      b=$(dlg "Hey 👋  Wolf Leader v1 gave every agent you use one shared memory. This update builds on it: chats save themselves, every project is one question away in any new chat, and you can pick up on any machine." "Continue")
    fi
    case "$b" in
      "See what's new") open "$ASSETS/whatsnew-cards.png" ;;
      Continue) return 0 ;;
      *) confirm_quit ;;
    esac
  done
}

page_mode() {
  local def r b
  def=$L_CONNECT
  if [ -f "$HOME/.cursor/rules/wolf-leader-hub.mdc" ] || [ -d "$HOME/.cursor/skills/save" ]; then
    def=$L_UPDATE
  fi
  while :; do
    r=$(dlg_list "Do you already have Wolf Leader?

New hub: the hub runs in Docker. An always-on box (NAS, Proxmox LXC, Linux server) is the tested setup; a hub on your desktop works but is experimental." 0 "$def" "$L_NEW" "$L_CONNECT" "$L_UPDATE")
    case "$r" in
      "OK:$L_NEW") MODE=new ;;
      "OK:$L_CONNECT") MODE=connect ;;
      "OK:$L_UPDATE") MODE=update ;;
      "OK:") continue ;;
      *) confirm_quit; continue ;;
    esac
    if [ "$MODE" = new ] && ! has docker && [ ! -d /Applications/Docker.app ]; then
      b=$(dlg "A new hub runs in Docker, and Docker Desktop is not on this Mac yet.

Install Docker Desktop, start it once, then come back. Or go back and connect to an existing hub instead." "Go back" "Get Docker" "Continue anyway")
      case "$b" in
        "Get Docker") open "https://www.docker.com/products/docker-desktop/"; continue ;;
        "Continue anyway") ;;
        *) continue ;;
      esac
    fi
    wlog "mode=$MODE"
    return 0
  done
}

page_toggles() {
  local r sel all
  if [ "$MODE" = new ]; then
    all="$T_CLIENT
$T_SHARES
$T_PREREQS
$T_OBSIDIAN
$T_WIKI"
  else
    all="$T_CLIENT
$T_SHARES
$T_PREREQS
$T_OBSIDIAN"
  fi
  while :; do
    if [ "$MODE" = new ]; then
      r=$(dlg_list "What do you want? (Cmd-click to change the selection)" 1 "$all" \
        "$T_CLIENT" "$T_SHARES" "$T_PREREQS" "$T_OBSIDIAN" "$T_WIKI")
    else
      r=$(dlg_list "What do you want? (Cmd-click to change the selection)" 1 "$all" \
        "$T_CLIENT" "$T_SHARES" "$T_PREREQS" "$T_OBSIDIAN")
    fi
    case "$r" in OK:*) break ;; *) confirm_quit ;; esac
  done
  sel=${r#OK:}
  TOGGLES=""
  add_toggle() { TOGGLES="${TOGGLES:+$TOGGLES,}$1"; }
  case "$sel" in *"$T_CLIENT"*) add_toggle client ;; esac
  case "$sel" in *"$T_SHARES"*) add_toggle shares ;; esac
  case "$sel" in *"$T_PREREQS"*) add_toggle prereqs ;; esac
  case "$sel" in *"$T_OBSIDIAN"*) add_toggle obsidian ;; esac
  if [ "$MODE" = new ]; then
    case "$sel" in *"$T_WIKI"*) add_toggle wiki ;; esac
  fi
  wlog "toggles=${TOGGLES:-none}"
}

has_toggle() { case ",$TOGGLES," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

prompt_awk() {
  cat <<'AWK'
function rep(s, a, b,   i, out) {
  out = ""
  while ((i = index(s, a)) > 0) { out = out substr(s, 1, i - 1) b; s = substr(s, i + length(a)) }
  return out s
}
/^---[ \t]*$/ { n++; if (n >= 2) exit; next }
n == 1 {
  line = rep($0, "{{OS}}", os); line = rep(line, "{{MODE}}", mode); line = rep(line, "{{HUB_HINT}}", hint)
  buf[++c] = line
}
END {
  s = 1; while (s <= c && buf[s] ~ /^[ \t]*$/) s++
  e = c; while (e >= s && buf[e] ~ /^[ \t]*$/) e--
  for (i = s; i <= e; i++) print buf[i]
}
AWK
}

render_prompt() {
  local hint="http://wolf.local:6971"
  [ "$MODE" = new ] && hint="http://localhost:6971"
  awk -v os=mac -v mode="$MODE" -v hint="$hint" "$(prompt_awk)" "$ROOT/installer/PROMPT.md" >"$WORK/prompt.txt"
  [ -s "$WORK/prompt.txt" ]
}

copy_prompt() { pbcopy <"$WORK/prompt.txt"; }

# Validate $WORK/reply.txt; on success leaves $WORK/answers.ini + $WORK/cfg and returns 0.
check_reply() {
  local errs shown b
  wl_ini_extract "$WORK/reply.txt" >"$WORK/answers.ini"
  if wl_ini_parse "$WORK/answers.ini" mac >"$WORK/cfg"; then
    return 0
  fi
  errs=$(cat "$WORK/cfg")
  shown=$(printf '%s\n' "$errs" | head -n 16)
  [ "$(printf '%s\n' "$errs" | wc -l)" -gt 16 ] && shown="$shown
  ...and more"
  {
    printf 'The Wolf Leader installer rejected your answer. Fix these and reply with the complete ini block again (one ```ini code block, nothing else):\n\n'
    printf '%s\n' "$errs"
  } | pbcopy
  wlog "answer rejected: $(printf '%s' "$errs" | head -n 1)"
  b=$(dlg "That answer is not quite right yet:

$shown

These errors are now on your clipboard. Paste them to your agent, copy its new reply, then click Try again." "Cancel" "Copy questions again" "Try again")
  case "$b" in
    "Copy questions again") copy_prompt ;;
    Cancel) confirm_quit ;;
  esac
  return 1
}

page_agent() {
  local b r f
  render_prompt || {
    dlg "Setup files are incomplete (installer/PROMPT.md is missing). Download Wolf Leader Setup again." "Quit" >/dev/null
    exit 1
  }
  copy_prompt
  while :; do
    b=$(dlg "Ask your AI agent

Your agent fills in the setup details for you. The questions are now on your clipboard.

1. Open Cursor, Claude or ChatGPT on THIS Mac (it needs to look at this computer).
2. Paste (Cmd-V) and send.
3. When it answers, copy its whole reply (the ini block).
4. Come back and click Paste reply.

Already have a wolf-leader-setup.ini file? Click Choose file." "Cancel" "Choose file…" "Paste reply")
    case "$b" in
      "Paste reply")
        pbpaste >"$WORK/reply.txt"
        if [ ! -s "$WORK/reply.txt" ]; then
          dlg "Your clipboard is empty. Copy the agent's reply first, then click Paste reply." "OK" >/dev/null
          continue
        fi
        if grep -q "You are helping me install" "$WORK/reply.txt"; then
          b=$(dlg "Your clipboard still has the questions, not the agent's answer.

Paste them into your agent, then copy its reply and click Paste reply." "Copy questions again" "OK")
          [ "$b" = "Copy questions again" ] && copy_prompt
          continue
        fi
        ;;
      "Choose file…")
        r=$(dlg_file "Choose the wolf-leader-setup.ini your agent wrote")
        case "$r" in OK:*) f=${r#OK:} ;; *) continue ;; esac
        cat "$f" >"$WORK/reply.txt" 2>/dev/null || { dlg "Could not read $f." "OK" >/dev/null; continue; }
        ;;
      *) confirm_quit; continue ;;
    esac
    if check_reply; then
      wl_cfg_load "$WORK/cfg"
      wlog "answer accepted (hub $(wl_cfg wolf hub_url), shares: $(wl_cfg meta shares))"
      return 0
    fi
  done
}

page_passwords() {
  local s url user r pw
  rm -f "$WORK/secrets"
  has_toggle shares || return 0
  for s in $(wl_cfg meta shares); do
    [ "$(wl_cfg "$s" password)" = ASK ] || continue
    url=$(wl_cfg "$s" smb_url)
    user=$(wl_cfg "$s" user)
    while :; do
      r=$(dlg_input "Password for the network share

$url
User: $user

It is saved in your login Keychain, never in a file or the log." "" 1)
      case "$r" in
        OK:?*) pw=${r#OK:}; break ;;
        OK:) dlg "Please type the password (or Cancel to quit)." "OK" >/dev/null ;;
        *) confirm_quit ;;
      esac
    done
    printf '%s=%s\n' "$s" "$pw" >>"$WORK/secrets"
    pw=""
    r=""
  done
  return 0
}

page_identity() {
  local hint r
  GIT_NAME=""
  GIT_EMAIL=""
  if git_usable; then
    GIT_NAME=$(git config --global user.name 2>/dev/null)
    GIT_EMAIL=$(git config --global user.email 2>/dev/null)
  fi
  hint="Used only for local git commits. Real or made-up is fine (e.g. you@example.com) — this stops git from stopping to ask for a GitHub login."
  while :; do
    r=$(dlg_input "Your name for git

$hint" "$GIT_NAME" 0)
    case "$r" in
      OK:*) GIT_NAME=${r#OK:} ;;
      *) confirm_quit; continue ;;
    esac
    [ -n "$(printf '%s' "$GIT_NAME" | tr -d ' \t')" ] && break
    dlg "A name is required (any name is fine)." "OK" >/dev/null
  done
  while :; do
    r=$(dlg_input "Your email for git

$hint" "$GIT_EMAIL" 0)
    case "$r" in
      OK:*) GIT_EMAIL=${r#OK:} ;;
      *) confirm_quit; continue ;;
    esac
    case "$GIT_EMAIL" in
      *" "*) ;;
      ?*@?*) break ;;
    esac
    dlg "Please enter an email address like you@example.com (made-up is fine)." "OK" >/dev/null
  done
  wlog "git identity set for the summary"
}

page_summary() {
  local mode_label todo shares_txt s abk abk_txt b n
  case "$MODE" in
    new) mode_label=$L_NEW ;;
    connect) mode_label="Connect this Mac to an existing hub" ;;
    *) mode_label=$L_UPDATE ;;
  esac

  BACKUP_DIR="$HOME/Library/Application Support/WolfLeader/backup-$(date +%Y%m%d-%H%M)"
  n=2
  while [ -e "$BACKUP_DIR" ]; do BACKUP_DIR="${BACKUP_DIR%-[0-9]}-$n"; n=$((n + 1)); done

  shares_txt=""
  for s in $(wl_cfg meta shares); do
    shares_txt="$shares_txt
     $(wl_cfg "$s" smb_url) ($(wl_cfg "$s" role))"
  done

  todo=""
  has_toggle client && todo="$todo
  • Cursor / Claude Code client (skills, rule, MCP; no hooks)"
  if has_toggle shares; then
    if [ -n "$shares_txt" ]; then todo="$todo
  • Map network shares:$shares_txt"
    else todo="$todo
  • Map network shares: none listed by your agent"
    fi
  fi
  has_toggle prereqs && todo="$todo
  • Git + Python if missing"
  has_toggle obsidian && todo="$todo
  • Obsidian"
  if [ "$MODE" = new ]; then
    if has_toggle wiki; then todo="$todo
  • New hub in Docker, with the wiki (first build can take 10-15 min)"
    else todo="$todo
  • New hub in Docker, without the wiki"
    fi
  fi
  todo="$todo
  • Git identity: $GIT_NAME <$GIT_EMAIL>"

  abk=$(wl_cfg backup path)
  case "$abk" in "~/"*) abk="$HOME/${abk#\~/}" ;; esac
  if [ "$(wl_cfg backup done)" != yes ]; then
    abk_txt="Note: your agent did not make a backup. Setup's own undo point below still covers every file it changes."
  elif [ ! -d "$abk" ]; then
    abk_txt="Note: your agent said it saved a backup to
  $abk
but that folder is not on this Mac. Setup's own undo point below still covers every file it changes."
  else
    abk_txt="Your agent's backup: $abk ($(wl_cfg backup files) files)"
  fi

  b=$(dlg "Ready to install

$mode_label
Hub: $(wl_cfg wolf hub_url)   MCP: $(wl_cfg wolf mcp_url)
This Mac: $(wl_cfg wolf device_name), $(wl_cfg wolf timezone)

Setup will:$todo

$abk_txt

Before changing anything, Setup saves the files it touches to:
  $BACKUP_DIR
(run restore.sh there to undo)

macOS may ask to allow access to System Events (for Login Items) or Keychain. Click OK.
Log: ~/Library/Logs/WolfLeader/install.log" "Cancel" "Start over" "Install")
  case "$b" in
    Install) return 0 ;;
    "Start over") return 1 ;;
    *) confirm_quit; return 1 ;;
  esac
}

run_install() {
  local rc out=/dev/stdout
  wlog "running install.sh (mode=$MODE toggles=${TOGGLES:-none})"
  : >"$WORK/result"
  # install.sh tees into the log itself; without a terminal its stdout would duplicate every line.
  [ "$HAS_TTY" = 1 ] || out=/dev/null
  if [ "$HAS_TTY" = 0 ]; then
    notify "Installing… progress is shown in the log window."
    open -a Console "$LOG" >/dev/null 2>&1 || true
  else
    printf '\nInstalling. Progress below (also in %s).\n\n' "$LOG"
  fi
  if [ -s "$WORK/secrets" ]; then
    WL_SECRETS_FILE="$WORK/secrets" /bin/bash "$SCRIPT_DIR/install.sh" --ini "$WORK/answers.ini" \
      --mode "$MODE" --toggles "$TOGGLES" --git-name "$GIT_NAME" --git-email "$GIT_EMAIL" \
      --backup-dir "$BACKUP_DIR" --result "$WORK/result" >"$out" 2>&1
  else
    /bin/bash "$SCRIPT_DIR/install.sh" --ini "$WORK/answers.ini" \
      --mode "$MODE" --toggles "$TOGGLES" --git-name "$GIT_NAME" --git-email "$GIT_EMAIL" \
      --backup-dir "$BACKUP_DIR" --result "$WORK/result" >"$out" 2>&1
  fi
  rc=$?
  rm -f "$WORK/secrets"
  wlog "install.sh exited $rc"
  return $rc
}

res() { awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' "$WORK/result" 2>/dev/null; }

page_finish() {
  local status health hurl hbody bdir reason head htxt notes b
  status=$(res status)
  health=$(res health)
  hurl=$(res health_url)
  hbody=$(res health_body)
  bdir=$(res backup_dir)
  [ -n "$bdir" ] || bdir=$BACKUP_DIR
  reason=$(res reason)
  notes=$(awk -F= '$1 == "note" { sub(/^note=/, ""); print "  • " $0 }' "$WORK/result" 2>/dev/null | head -n 8)

  if [ "$status" = ok ]; then
    head="Wolf Leader is installed."
  else
    head="Setup stopped before finishing.

${reason:-Something went wrong; see the log.}"
  fi
  case "$health" in
    ok) htxt="Hub check: OK, $hurl answered." ;;
    fail) htxt="Hub check: no answer from $hurl. Is the hub running and is this Mac on the same network? ($hbody)" ;;
    *) htxt="Hub check: not run." ;;
  esac

  while :; do
    b=$(dlg "$head

$htxt
${notes:+
Next:
$notes
}
Undo: everything Setup changed was saved to
  $bdir
Run restore.sh there to undo (Terminal: bash \"$bdir/restore.sh\").

Log: ~/Library/Logs/WolfLeader/install.log" "Open log" "Show undo folder" "Done")
    case "$b" in
      "Open log") open "$LOG" ;;
      "Show undo folder") open "$bdir" 2>/dev/null || open "$HOME/Library/Application Support/WolfLeader" ;;
      *) return 0 ;;
    esac
  done
}

# --- main --------------------------------------------------------------------------------------
wlog "started from $ROOT"
MODE=""
TOGGLES=""
GIT_NAME=""
GIT_EMAIL=""
BACKUP_DIR=""

page_welcome
while :; do
  page_mode
  page_toggles
  page_agent
  page_passwords
  page_identity
  page_summary && break
  rm -f "$WORK/secrets"
done

run_install
RC=$?
page_finish
if [ "$HAS_TTY" = 1 ]; then exit $RC; fi
exit 0
