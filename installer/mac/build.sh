#!/bin/bash
# Package the Mac installer for sending to a friend (run on a Mac, from anywhere):
#
#   bash installer/mac/build.sh [version]
#
# Produces:
#   dist/Wolf Leader Setup.app          AppleScript applet (osacompile) that runs the bundled wizard
#                                       from Contents/Resources/installer/mac/wizard.sh
#   dist/WolfLeaderSetup-<ver>.dmg      compressed disk image with the app (+ background if available)
#
# The app is ad-hoc signed only (no Apple Developer ID), so the first launch is blocked by Gatekeeper:
#   macOS 14 and older: right-click the app > Open > Open.
#   macOS 15 and newer: double-click once, then System Settings > Privacy & Security > "Open Anyway".
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"

if [ "$(uname -s)" != Darwin ]; then
  echo "build.sh must run on macOS (it needs osacompile, sips, codesign and hdiutil)." >&2
  exit 1
fi

VERSION="${1:-${WL_VERSION:-}}"
if [ -z "$VERSION" ]; then
  VERSION=$(sed -n 's/.*FastAPI(.*version="\([0-9][0-9.]*\)".*/\1/p' ide_storage/main.py | head -n 1)
fi
[ -n "$VERSION" ] || VERSION=$(date +%Y.%m.%d)

DIST="$ROOT/dist"
APP="$DIST/Wolf Leader Setup.app"
RES="$APP/Contents/Resources"
ASSETS="$ROOT/installer/assets"
STAGE="$DIST/dmg-stage"
DMG="$DIST/WolfLeaderSetup-$VERSION.dmg"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/wl-build.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

echo "Building Wolf Leader Setup $VERSION"
rm -rf "$APP" "$STAGE" "$DMG"
mkdir -p "$DIST"

# --- 1. the applet --------------------------------------------------------------------------
cat >"$TMP/applet.applescript" <<'AS'
on run
	set resDir to (POSIX path of (path to me)) & "Contents/Resources/"
	set wizard to resDir & "installer/mac/wizard.sh"
	try
		do shell script "/bin/bash " & quoted form of wizard & " --from-app"
	on error errMsg number errNum
		if errNum is not -128 then
			display dialog "Wolf Leader Setup stopped." & return & return & errMsg & return & return & "Details: ~/Library/Logs/WolfLeader/install.log" with title "Wolf Leader Setup" buttons {"OK"} default button "OK" with icon caution
		end if
	end try
end run
AS
osacompile -o "$APP" "$TMP/applet.applescript"

# --- 2. bundle the files the wizard and a new hub need --------------------------------------
EXCL=(--exclude __pycache__ --exclude '*.pyc' --exclude .DS_Store)
mkdir -p "$RES/installer/mac"
cp installer/mac/wizard.sh installer/mac/install.sh installer/mac/ini.sh "installer/mac/Wolf Leader Setup.command" \
  "$RES/installer/mac/"
cp installer/CONFIG.md installer/PROMPT.md "$RES/installer/"
if [ -d "$ASSETS" ]; then
  mkdir -p "$RES/installer/assets"
  rsync -a "${EXCL[@]}" --exclude '*.html' --exclude '*.bmp' --exclude '*.py' --exclude README.md \
    "$ASSETS/" "$RES/installer/assets/"
else
  echo "  note: installer/assets not found; building without icon/what's-new/background"
fi

# client files
rsync -a "${EXCL[@]}" examples "$RES/"
# hub files (mode=new copies these to ~/WolfLeader/hub and builds them with Docker)
rsync -a "${EXCL[@]}" ide_storage scripts "$RES/"
rsync -a "${EXCL[@]}" --exclude node_modules --exclude .next --exclude out --exclude .source \
  --exclude next-env.d.ts --exclude '*.tsbuildinfo' wiki "$RES/"
for f in Dockerfile .dockerignore docker-compose*.yml requirements*.txt .env.example start.sh \
  README.md INSTALL.md AGENTS.md; do
  if [ -e "$f" ]; then cp "$f" "$RES/"; fi
done
if [ -d data/projects/_example ]; then
  mkdir -p "$RES/data/projects"
  rsync -a "${EXCL[@]}" data/projects/_example "$RES/data/projects/"
fi

# A Windows checkout may have CRLF scripts; bash on the Mac needs LF.
find "$RES" -type f \( -name '*.sh' -o -name '*.command' -o -name '*.py' \) -print0 \
  | xargs -0 perl -pi -e 's/\r$//'
find "$RES" -type f \( -name '*.sh' -o -name '*.command' \) -print0 | xargs -0 chmod +x

# --- 3. icon + Info.plist -------------------------------------------------------------------
ICON_SRC="$ASSETS/app-icon.png"
[ -f "$ICON_SRC" ] || ICON_SRC="$ASSETS/mac-icon.png"
if [ -f "$ICON_SRC" ]; then
  if sips -z 1024 1024 "$ICON_SRC" --out "$TMP/icon.png" >/dev/null 2>&1 \
    && sips -s format icns "$TMP/icon.png" --out "$TMP/icon.icns" >/dev/null 2>&1; then
    cp "$TMP/icon.icns" "$RES/applet.icns"
    cp "$TMP/icon.icns" "$RES/installer/assets/mac-icon.icns"
    echo "  icon: from ${ICON_SRC#$ROOT/}"
  else
    echo "  note: could not convert ${ICON_SRC##*/} to .icns; keeping the default applet icon"
  fi
fi
PLIST="$APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "com.wolfleader.setup" "$PLIST"
plutil -replace CFBundleShortVersionString -string "$VERSION" "$PLIST"
plutil -replace CFBundleName -string "Wolf Leader Setup" "$PLIST"

# Resources changed after osacompile signed the applet; re-sign ad-hoc or Apple Silicon
# reports the app as "damaged".
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
echo "  app:  $APP"

# --- 4. the disk image ----------------------------------------------------------------------
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
if [ -f "$ASSETS/whatsnew-cards.png" ]; then cp "$ASSETS/whatsnew-cards.png" "$STAGE/What's new.png"; fi
cat >"$STAGE/Read me first.txt" <<'TXT'
Wolf Leader Setup

1. Drag "Wolf Leader Setup" anywhere you like (or run it from here).
2. Open it. The first time, macOS blocks apps from outside the App Store:
   - macOS 14 or older: right-click "Wolf Leader Setup" > Open > Open.
   - macOS 15 or newer: double-click it once, then open System Settings >
     Privacy & Security, scroll down and click "Open Anyway".
3. Follow the windows. Setup saves everything it changes first, so you can undo it
   (it shows you where at the end).

Log: ~/Library/Logs/WolfLeader/install.log
TXT

finder_layout_script() {
  cat <<'AS'
on run argv
  set volName to item 1 of argv
  set w to (item 2 of argv) as integer
  set h to (item 3 of argv) as integer
  tell application "Finder"
    tell disk volName
      open
      set current view of container window to icon view
      set toolbar visible of container window to false
      set statusbar visible of container window to false
      set the bounds of container window to {200, 120, 200 + w, 120 + h}
      set opts to the icon view options of container window
      set arrangement of opts to not arranged
      set icon size of opts to 112
      set background picture of opts to file ".background:background.png"
      try
        set position of item "Wolf Leader Setup.app" of container window to {(w * 0.3) as integer, (h * 0.5) as integer}
      end try
      try
        set position of item "What's new.png" of container window to {(w * 0.7) as integer, (h * 0.35) as integer}
      end try
      try
        set position of item "Read me first.txt" of container window to {(w * 0.7) as integer, (h * 0.7) as integer}
      end try
      close
      open
      update without registering applications
      delay 2
      close
    end tell
  end tell
end run
AS
}

# Background via Finder layout. Needs permission for Terminal to control Finder; any failure
# falls back to a plain image.
fancy_dmg() {
  local rw="$TMP/rw.dmg" out dev mnt vol w h
  [ -f "$ASSETS/dmg-background.png" ] || return 1
  mkdir -p "$STAGE/.background"
  cp "$ASSETS/dmg-background.png" "$STAGE/.background/background.png"
  w=$(sips -g pixelWidth "$ASSETS/dmg-background.png" 2>/dev/null | awk '/pixelWidth/ { print $2 }')
  h=$(sips -g pixelHeight "$ASSETS/dmg-background.png" 2>/dev/null | awk '/pixelHeight/ { print $2 }')
  [ -n "$w" ] && [ -n "$h" ] || { w=660; h=400; }
  hdiutil create -volname "Wolf Leader" -srcfolder "$STAGE" -ov -fs HFS+ -format UDRW "$rw" >/dev/null || return 1
  out=$(hdiutil attach -readwrite -noverify -noautoopen "$rw") || return 1
  dev=$(printf '%s\n' "$out" | awk '/\/Volumes\// { print $1; exit }')
  mnt=$(printf '%s\n' "$out" | awk -F'\t' '/\/Volumes\// { print $NF; exit }')
  vol=$(basename "$mnt")
  if ! osascript - "$vol" "$w" "$h" <<<"$(finder_layout_script)"; then
    hdiutil detach "$dev" -force >/dev/null 2>&1 || true
    return 1
  fi
  chmod -Rf go-w "$mnt" || true
  sync
  hdiutil detach "$dev" >/dev/null 2>&1 || hdiutil detach "$dev" -force >/dev/null 2>&1 || return 1
  hdiutil convert "$rw" -format UDZO -imagekey zlib-level=9 -o "$DMG" >/dev/null || return 1
}

if fancy_dmg; then
  echo "  dmg:  $DMG (with background)"
else
  echo "  note: no custom DMG background (asset missing or Finder layout not permitted); building a plain image"
  rm -rf "$STAGE/.background" "$DMG"
  hdiutil create -volname "Wolf Leader" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
  echo "  dmg:  $DMG"
fi
rm -rf "$STAGE"
echo "Done. Send $DMG; tell your friend about right-click > Open (see Read me first.txt)."
