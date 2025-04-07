#!/bin/bash

# === Set APP_RESOURCES_PATH if missing ===
if [ -z "$APP_RESOURCES_PATH" ]; then
  APP_RESOURCES_PATH="$(dirname "$0")/../Resources"
fi

# === If app was called with "sync" argument, just run sync.sh and exit ===
if [[ "$1" == "sync" ]]; then
  "$APP_RESOURCES_PATH/sync.sh"
  exit 0
fi

# === README Popup on First Launch ===
APP_SUPPORT_DIR="$HOME/Library/Application Support/SyncZettelkasten"
README_SHOWN_FLAG="$APP_SUPPORT_DIR/readme_shown"
README_FILE="$APP_RESOURCES_PATH/README.txt"

mkdir -p "$APP_SUPPORT_DIR"

if [ ! -f "$README_SHOWN_FLAG" ] && [ -f "$README_FILE" ]; then
  # Try open with fallback
  open -a TextEdit "$README_FILE" 2>/dev/null
  osascript -e 'tell application "TextEdit" to activate' \
            -e 'tell application "TextEdit" to open POSIX file "'"$README_FILE"'"'
  touch "$README_SHOWN_FLAG"
fi

exit_script() {
  echo "Exiting cleanly at $(date)" >> ~/Desktop/zetta_exit_log.txt
  pkill -f "Sync Zettelkasten"
  kill $PPID 2>/dev/null
  exit 0
}

# ========== Setup jq ==========
if [ -z "$APP_RESOURCES_PATH" ]; then
  APP_RESOURCES_PATH="$(dirname "$0")/../Resources"
fi
JQ="$APP_RESOURCES_PATH/jq"
if [ ! -x "$JQ" ]; then
  osascript -e 'display dialog "⚠️ jq binary not found in app resources.\nPlease re-bundle this app." buttons {"OK"}'
  exit_script
fi

# ========== Config Setup ==========
CONFIG_DIR="$HOME/Library/Application Support/SyncZettelkasten"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

# Create a default config if it doesn't exist yet
if [ ! -f "$CONFIG_FILE" ]; then
  cat <<EOF > "$CONFIG_FILE"
{
  "googleDrivePath": "",
  "icloudPath": "",
  "backupRetentionPeriod": 30,
  "syncTimes": {
    "firstSyncTime": "10:00 AM",
    "secondSyncTime": "12:14 PM"
  }
}
EOF
fi

# ========== Start App Menu ==========
while true; do
  MODE=$(osascript -e 'choose from list {"Edit Preferences", "Sync Now", "Install SwiftBar Plugin", "Quit"} with prompt "What would you like to do?" default items {"Sync Now"}')
  if [[ "$MODE" == "false" || "$MODE" == "Quit" ]]; then
    exit_script
  fi

  # ========= Preferences Mode =========
  if [[ "$MODE" == "Edit Preferences" ]]; then
    GOOGLE_DRIVE_PATH=$(osascript -e 'try
      set dialogResult to display dialog "Enter your MAIN Folder Path:" default answer ""
      return text returned of dialogResult
    on error
      return "CANCELLED"
    end try')
    if [[ "$GOOGLE_DRIVE_PATH" == "CANCELLED" ]]; then continue; fi

    ICLOUD_PATH=$(osascript -e 'try
      set dialogResult to display dialog "Enter desired BACKUP folder path:" default answer ""
      return text returned of dialogResult
    on error
      return "CANCELLED"
    end try')
    if [[ "$ICLOUD_PATH" == "CANCELLED" ]]; then continue; fi

    BACKUP_RETENTION_PERIOD=$(osascript -e 'try
      set dialogResult to display dialog "Enter Backup Retention Period (in days):" default answer "30"
      return text returned of dialogResult
    on error
      return "CANCELLED"
    end try')
    if [[ "$BACKUP_RETENTION_PERIOD" == "CANCELLED" ]]; then continue; fi

    if ! [[ "$BACKUP_RETENTION_PERIOD" =~ ^[0-9]+$ ]]; then
      osascript -e 'display dialog "❌ Backup retention must be a number." buttons {"OK"}'
      continue
    fi

    cat <<EOF > "$CONFIG_FILE"
{
  "googleDrivePath": "$(echo "$GOOGLE_DRIVE_PATH" | sed 's/"/\\"/g')",
  "icloudPath": "$(echo "$ICLOUD_PATH" | sed 's/"/\\"/g')",
  "backupRetentionPeriod": $BACKUP_RETENTION_PERIOD,
  "syncTimes": {
    "firstSyncTime": "10:00 AM",
    "secondSyncTime": "10:00 PM"
  }
}
EOF

    osascript -e 'display dialog "✅ Preferences saved!" buttons {"OK"}'

  # === Install LaunchAgent and Background Sync ===
    APP_SUPPORT_DIR="$HOME/Library/Application Support/SyncZettelkasten"
    mkdir -p "$APP_SUPPORT_DIR"
    cp "$APP_RESOURCES_PATH/sync.sh" "$APP_SUPPORT_DIR/"
    cp "$APP_RESOURCES_PATH/jq" "$APP_SUPPORT_DIR/"
    chmod +x "$APP_SUPPORT_DIR/sync.sh"

    # Setup LaunchAgent .plist
    PLIST_SRC="$APP_RESOURCES_PATH/com.berdasco.obsidiansync.plist"
    PLIST_DEST="$HOME/Library/LaunchAgents/com.berdasco.obsidiansync.plist"

    mkdir -p "$HOME/Library/LaunchAgents"
    cp "$PLIST_SRC" "$PLIST_DEST"

    # Replace hardcoded path inside .plist with the real one
    sed -i '' "s|/Users/berdasco/Library/Application Support/SyncZettelkasten|$APP_SUPPORT_DIR|g" "$PLIST_DEST"

    # Load the LaunchAgent
    launchctl unload "$PLIST_DEST" 2>/dev/null
    launchctl load "$PLIST_DEST"

    continue
  fi

  # ========= SwiftBar Plugin Install =========
  if [[ "$MODE" == "Install SwiftBar Plugin" ]]; then
    SWIFTBAR_PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
    if [ ! -d "$SWIFTBAR_PLUGIN_DIR" ]; then
      osascript -e 'display dialog "⚠️ SwiftBar not found.\nPlease install SwiftBar from https://swiftbar.app and run it once." buttons {"OK"}'
      continue
    fi

    PLUGIN_SRC="$APP_RESOURCES_PATH/zettelkasten_sync.10m.sh"
    PLUGIN_DEST="$SWIFTBAR_PLUGIN_DIR/zettelkasten_sync.10m.sh"

    sed "s|__HOME__|$HOME|g" "$PLUGIN_SRC" > "$PLUGIN_DEST"
    chmod +x "$PLUGIN_DEST"

    # === Create wrapper script for SwiftBar ===
    WRAPPER="$HOME/bin/run_sync_zettelkasten.sh"
    mkdir -p "$HOME/bin"
    cat <<EOF > "$WRAPPER"
#!/bin/bash
"$HOME/Library/Application Support/SyncZettelkasten/sync.sh"
EOF
    chmod +x "$WRAPPER"

    osascript -e 'display dialog "✅ SwiftBar plugin installed!\n\nYou may need to enable it in SwiftBar." buttons {"OK"}'
    continue
  fi

  # ========= Sync Mode =========
  if [[ "$MODE" == "Sync Now" ]]; then
    if [ ! -f "$CONFIG_FILE" ]; then
      osascript -e 'display dialog "❌ Preferences not set. Please choose Edit Preferences first." buttons {"OK"}'
      continue
    fi

    GOOGLE_DRIVE_PATH=$("$JQ" -r '.googleDrivePath' "$CONFIG_FILE")
    ICLOUD_PATH=$("$JQ" -r '.icloudPath' "$CONFIG_FILE")
    BACKUP_RETENTION_PERIOD=$("$JQ" -r '.backupRetentionPeriod' "$CONFIG_FILE")

    LOG="$HOME/sync_debug.log"
    RSYNC_OUTPUT=$(mktemp)
    LOCKFILE="/tmp/zettelkasten_sync.lock"
    TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
    DAYSTAMP=$(date "+%Y-%m-%d")
    BACKUP_BASE="$ICLOUD_PATH/deleted_zettels/$DAYSTAMP"
    BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"

    if [ -f "$LOCKFILE" ]; then
      echo "Another sync is already running. Exiting at $(date)." >> "$LOG"
      exit_script
    fi

    touch "$LOCKFILE"
    trap "rm -f $LOCKFILE" EXIT

    find "$BACKUP_BASE" -type d -mindepth 1 -maxdepth 1 -mtime +"$BACKUP_RETENTION_PERIOD" -exec rm -rf {} \;

    echo "==== Sync started at $(date) ====" >> "$LOG"
    rsync -av --backup --backup-dir="$BACKUP_DIR" \
      --delete "$GOOGLE_DRIVE_PATH" \
      "$ICLOUD_PATH" \
      | tee "$RSYNC_OUTPUT" >> "$LOG"

    ADDED_MODIFIED=$(grep -vE '^sending|^sent|^total|^deleting|^\./$' "$RSYNC_OUTPUT" | wc -l)
    DELETED=$(grep '^deleting ' "$RSYNC_OUTPUT" | wc -l)

    echo "Added/Modified: $ADDED_MODIFIED" >> "$LOG"
    echo "Deleted: $DELETED" >> "$LOG"
    echo "Backup saved to: $BACKUP_DIR" >> "$LOG"
    echo "Sync finished at $(date)" >> "$LOG"

    if [ -x /opt/homebrew/bin/terminal-notifier ]; then
      /opt/homebrew/bin/terminal-notifier -title "Zettelkasten Sync" \
        -message "✅ $ADDED_MODIFIED changed, 🗑️ $DELETED deleted"
    else
      osascript -e "display notification \"✅ $ADDED_MODIFIED changed, 🗑️ $DELETED deleted\" with title \"Zettelkasten Sync\""
    fi

    rm "$RSYNC_OUTPUT"
    continue
  fi
done
