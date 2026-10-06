#!/bin/bash
# Double-click to set up Wolf Leader on this Mac (Finder opens .command files in Terminal).
# If macOS says it "cannot be opened": right-click > Open, or in Terminal run
#   chmod +x "Wolf Leader Setup.command"
cd "$(dirname "$0")" || exit 1
/bin/bash ./wizard.sh "$@"
