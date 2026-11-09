#!/usr/bin/env bash
# Captures README screenshots from the iOS Simulator using the app's
# deterministic demo scenes (launch argument `-demoScene <name>`).
#
# Usage: scripts/take-screenshots.sh path/to/BuildAGoat.app [output-dir]
set -euo pipefail

APP_PATH="${1:?path to BuildAGoat.app}"
OUT_DIR="${2:-docs/screenshots}"
BUNDLE_ID="com.buildagoat.app"
mkdir -p "$OUT_DIR"

# Newest available simulator whose name starts with the given prefix.
find_device() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
prefix = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
matches = []
for runtime, items in devices.items():
    if "iOS" not in runtime:
        continue
    for d in items:
        if d["name"].startswith(prefix):
            matches.append((runtime, d["name"], d["udid"]))
matches.sort()
print(matches[-1][2] if matches else "")
' "$1"
}

capture() {
  local udid="$1" device_label="$2"; shift 2
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 || true
  xcrun simctl install "$udid" "$APP_PATH"

  for scene in "$@"; do
    xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE_ID" -demoScene "$scene" >/dev/null
    sleep 5   # let entrance animations settle
    xcrun simctl io "$udid" screenshot "$OUT_DIR/${device_label}-${scene}.png"
    echo "📸 ${device_label}-${scene}.png"
  done
  xcrun simctl shutdown "$udid" || true
}

IPHONE=$(find_device "iPhone 16 Pro")
[ -z "$IPHONE" ] && IPHONE=$(find_device "iPhone")
IPAD=$(find_device "iPad Pro 13")
[ -z "$IPAD" ] && IPAD=$(find_device "iPad Pro")

[ -n "$IPHONE" ] || { echo "No iPhone simulator found"; exit 1; }
capture "$IPHONE" iphone home builder drafting switching complete summary

if [ -n "$IPAD" ]; then
  capture "$IPAD" ipad drafting complete
fi
