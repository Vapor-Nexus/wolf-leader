#!/bin/bash
# Mac: double-click this after cloning Wolf Leader to run the setup wizard.
# If macOS says it "cannot be opened": right-click > Open, or run  chmod +x start.command
cd "$(dirname "$0")" || exit 1
echo "Wolf Leader setup"
echo "Setup windows will pop up; this Terminal window shows the progress."
echo ""
/bin/bash "installer/mac/Wolf Leader Setup.command"
rc=$?
echo ""
if [ "$rc" -eq 0 ]; then
  echo "All done. You can close this window."
else
  echo "Setup did not finish (code $rc). Details: ~/Library/Logs/WolfLeader/install.log"
fi
