#!/bin/bash

# === Set APP_RESOURCES_PATH if missing ===
if [ -z "$APP_RESOURCES_PATH" ]; then
  APP_RESOURCES_PATH="$(dirname "$0")/../Resources"
fi

# === README Popup on First Launch ===
APP_SUPPORT_DIR="$HOME/Library/Application Support/BerdSync"
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

# === Full app quit ===
exit_script() {
  killall "Sync Zettelkasten" 2>/dev/null
  kill $PPID 2>/dev/null
  exit 0
}

# === Exit just the sync loop (don't quit app) ===
sync_exit() {
  rm -f "$LOCKFILE"
  return
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
CONFIG_DIR="$HOME/Library/Application Support/BerdSync"
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
    "secondSyncTime": "10:00 PM"
  }
}
EOF
fi

# ========== Start App Menu ==========
while true; do
  MODE=$(osascript -e 'choose from list {"Sync Now", "Edit Preferences", "Edit Automatic Sync Times", "View Current Preferences", "Install SwiftBar Plugin", "Help (Open README)", "Full Disk Access Info", "Quit"} with prompt "What would you like to do?" default items {"Edit Preferences"} with title "BerdSync"')
  if [[ "$MODE" == "false" || "$MODE" == "Quit" ]]; then
    exit_script
  fi

# ========= Preferences Mode =========
    if [[ "$MODE" == "Edit Preferences" ]]; then
    GOOGLE_DRIVE_PATH=$(osascript -e 'try
      set dialogResult to display dialog "Enter your MAIN Folder Path:" default answer "" with title "BerdSync Setup"
      return text returned of dialogResult
    on error
      return "CANCELLED"
    end try')
    if [[ "$GOOGLE_DRIVE_PATH" == "CANCELLED" ]]; then continue; fi

    if [ ! -d "$GOOGLE_DRIVE_PATH" ]; then
      osascript -e 'display dialog "❌ The MAIN folder path does not exist. Please try again." buttons {"OK"} with title "Invalid Path"'
      continue
    fi

    ICLOUD_PATH=$(osascript -e 'try
      set dialogResult to display dialog "Enter desired BACKUP folder path:" default answer "" with title "BerdSync Setup"
      return text returned of dialogResult
    on error
      return "CANCELLED"
    end try')
    if [[ "$ICLOUD_PATH" == "CANCELLED" ]]; then continue; fi

    if [ ! -d "$ICLOUD_PATH" ]; then
      osascript -e 'display dialog "❌ The BACKUP folder path does not exist. Please try again." buttons {"OK"} with title "Invalid Path"'
      continue
    fi

    BACKUP_RETENTION_PERIOD=$(osascript -e 'try
      set dialogResult to display dialog "Enter Backup Retention Period (in days): (Leave empty or 0 to keep all backups)" default answer "" with title "BerdSync Setup"
      return text returned of dialogResult
    on error
      return "CANCELLED"
    end try')
    if [[ "$BACKUP_RETENTION_PERIOD" == "CANCELLED" ]]; then continue; fi

    if [[ -z "$BACKUP_RETENTION_PERIOD" ]]; then
      BACKUP_RETENTION_PERIOD=0
    fi

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
    APP_SUPPORT_DIR="$HOME/Library/Application Support/BerdSync"
    mkdir -p "$APP_SUPPORT_DIR"
    cp "$APP_RESOURCES_PATH/sync.sh" "$APP_SUPPORT_DIR/"
    cp "$APP_RESOURCES_PATH/jq" "$APP_SUPPORT_DIR/"
    chmod +x "$APP_SUPPORT_DIR/sync.sh"
    chmod +x "$APP_SUPPORT_DIR/jq"

    PLIST_SRC="$APP_RESOURCES_PATH/com.berdasco.obsidiansync.plist"
    PLIST_PATH="$HOME/Library/LaunchAgents/com.berdasco.obsidiansync.plist"
    USER_SYNC_SCRIPT="$APP_SUPPORT_DIR/sync.sh"

    mkdir -p "$HOME/Library/LaunchAgents"
    cp "$PLIST_SRC" "$PLIST_PATH"

    # === Inject new ProgramArguments block ===
    PROGRAM_BLOCK=$(mktemp)
    cat <<EOP > "$PROGRAM_BLOCK"
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$USER_SYNC_SCRIPT</string>
  </array>
EOP

    /usr/bin/sed "/^[[:space:]]*<key>ProgramArguments<\/key>/,/^[[:space:]]*<\/array>/d" "$PLIST_PATH" > "${PLIST_PATH}.tmp1"

    awk -v block="$PROGRAM_BLOCK" '
      FNR==NR { insert[NR]=$0; next }
      /<key>StartCalendarInterval<\/key>/ && !done {
        for (i=1; i<=length(insert); i++) {
          print insert[i]
        }
        done = 1
      }
      { print }
    ' "$PROGRAM_BLOCK" "${PLIST_PATH}.tmp1" > "${PLIST_PATH}.tmp2"

    if [ -s "${PLIST_PATH}.tmp2" ]; then
      mv "${PLIST_PATH}.tmp2" "$PLIST_PATH"
      rm -f "${PLIST_PATH}.tmp1" "$PROGRAM_BLOCK"
    else
      rm -f "${PLIST_PATH}.tmp1" "${PLIST_PATH}.tmp2" "$PROGRAM_BLOCK"
      osascript -e 'display dialog "❌ Failed to inject ProgramArguments." buttons {"OK"}'
      continue
    fi

    launchctl unload "$PLIST_PATH" 2>/dev/null
    launchctl load "$PLIST_PATH"
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
    BACKUP_BASE="$ICLOUD_PATH/file_backups/$DAYSTAMP"
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
    sync_exit
    continue
  fi
# ========= Help (Open README) =========
  if [[ "$MODE" == "Help (Open README)" ]]; then
    README_FILE="$APP_RESOURCES_PATH/README.txt"
    if [ -f "$README_FILE" ]; then
      open -a TextEdit "$README_FILE" 2>/dev/null || \
      osascript -e 'tell application "TextEdit" to activate' \
                -e 'tell application "TextEdit" to open POSIX file "'"$README_FILE"'"'
    else
      osascript -e 'display dialog "README file not found." buttons {"OK"} with title "Error"'
    fi
    continue
  fi
  
# === Full Disk Access Info Button ===
  if [[ "$MODE" == "Full Disk Access Info" ]]; then
    osascript -e 'display dialog "To ensure BerdSync works properly, especially with iCloud and external folders, please enable Full Disk Access.\n\n1. Open System Settings.\n2. Go to Privacy & Security > Full Disk Access.\n3. Click the + icon and add BerdSync.app.\n\nYou may need to restart the app after doing this." buttons {"OK"} with title "Grant Full Disk Access"'
    continue
  fi

# === View Current Preferences ===
if [[ "$MODE" == "View Current Preferences" ]]; then
  if [ -f "$CONFIG_FILE" ]; then
    GOOGLE_DRIVE_PATH=$("$JQ" -r '.googleDrivePath' "$CONFIG_FILE")
    ICLOUD_PATH=$("$JQ" -r '.icloudPath' "$CONFIG_FILE")
    RETENTION=$("$JQ" -r '.backupRetentionPeriod' "$CONFIG_FILE")
    FIRST_SYNC=$("$JQ" -r '.syncTimes.firstSyncTime // "Not set"' "$CONFIG_FILE")
    SECOND_SYNC=$("$JQ" -r '.syncTimes.secondSyncTime // "Not set"' "$CONFIG_FILE")

    if [[ "$RETENTION" -eq 0 ]]; then
      RETENTION_MSG="Disabled (keep everything)"
    else
      RETENTION_MSG="$RETENTION days"
    fi

    osascript -e "display dialog \"Google Drive Folder:\n$GOOGLE_DRIVE_PATH\n\niCloud Backup Folder:\n$ICLOUD_PATH\n\nRetention Period:\n$RETENTION_MSG\n\nFirst Sync Time:\n$FIRST_SYNC\nSecond Sync Time:\n$SECOND_SYNC\" buttons {\"OK\"} with title \"Current Preferences\""
  else
    osascript -e "display dialog \"Preferences not set yet.\" buttons {\"OK\"} with title \"Current Preferences\""
  fi
  continue
fi

# ========= Edit Sync Times =========
if [[ "$MODE" == "Edit Automatic Sync Times" ]]; then
  if [ ! -f "$CONFIG_FILE" ]; then
    osascript -e 'display dialog "❌ Preferences not set yet. Please set them first using Edit Preferences." buttons {"OK"}'
    continue
  fi

  FIRST_SYNC=$(osascript -e 'try
    set dialogResult to display dialog "Enter first daily sync time (e.g., 10:00 AM):" default answer "10:00 AM" with title "BerdSync – Edit Sync Times"
    return text returned of dialogResult
  on error
    return "CANCELLED"
  end try')
  if [[ "$FIRST_SYNC" == "CANCELLED" ]]; then continue; fi

  if ! date -j -f "%I:%M %p" "$FIRST_SYNC" "+%H:%M" >/dev/null 2>&1; then
    osascript -e 'display dialog "❌ Invalid format for First Sync Time.\nUse format like 10:00 AM or 3:30 PM." buttons {"OK"}'
    continue
  fi

  SECOND_SYNC=$(osascript -e 'try
    set dialogResult to display dialog "Enter second daily sync time (e.g., 10:00 PM):" default answer "10:00 PM" with title "BerdSync – Edit Sync Times"
    return text returned of dialogResult
  on error
    return "CANCELLED"
  end try')
  if [[ "$SECOND_SYNC" == "CANCELLED" ]]; then continue; fi

  if ! date -j -f "%I:%M %p" "$SECOND_SYNC" "+%H:%M" >/dev/null 2>&1; then
    osascript -e 'display dialog "❌ Invalid format for Second Sync Time.\nUse format like 10:00 AM or 3:30 PM." buttons {"OK"}'
    continue
  fi

  # Update config.json
  TMP_CONFIG=$(mktemp)
  "$JQ" --arg first "$FIRST_SYNC" --arg second "$SECOND_SYNC" \
    '.syncTimes.firstSyncTime = $first | .syncTimes.secondSyncTime = $second' \
    "$CONFIG_FILE" > "$TMP_CONFIG" && mv "$TMP_CONFIG" "$CONFIG_FILE"

  # === Update LaunchAgent plist ===
  PLIST_PATH="$HOME/Library/LaunchAgents/com.berdasco.obsidiansync.plist"

  if [ ! -f "$PLIST_PATH" ]; then
    osascript -e 'display dialog "❌ Could not find LaunchAgent plist to update." buttons {"OK"}'
    continue
  fi

  function parse_time() {
    date -j -f "%I:%M %p" "$1" +"%H %M"
  }

  read FIRST_HOUR FIRST_MIN <<< $(parse_time "$FIRST_SYNC")
  read SECOND_HOUR SECOND_MIN <<< $(parse_time "$SECOND_SYNC")

  # Remove old StartCalendarInterval block
  /usr/bin/sed "/^[[:space:]]*<key>StartCalendarInterval<\/key>/,/^[[:space:]]*<\/array>/d" "$PLIST_PATH" > "${PLIST_PATH}.tmp1"

  # Write new StartCalendarInterval block to file
  INSERT_BLOCK=$(mktemp)
  cat <<EOB > "$INSERT_BLOCK"
  <key>StartCalendarInterval</key>
  <array>
    <dict>
      <key>Hour</key>
      <integer>$FIRST_HOUR</integer>
      <key>Minute</key>
      <integer>$FIRST_MIN</integer>
    </dict>
    <dict>
      <key>Hour</key>
      <integer>$SECOND_HOUR</integer>
      <key>Minute</key>
      <integer>$SECOND_MIN</integer>
    </dict>
  </array>
EOB

  # Inject block before StandardOutPath
  awk -v block="$INSERT_BLOCK" '
    FNR==NR { insert[NR]=$0; next }
    /<key>StandardOutPath<\/key>/ && !done {
      for (i=1; i<=length(insert); i++) {
        print insert[i]
      }
      done = 1
    }
    { print }
  ' "$INSERT_BLOCK" "${PLIST_PATH}.tmp1" > "${PLIST_PATH}.tmp2"

  if [ -s "${PLIST_PATH}.tmp2" ]; then
    mv "${PLIST_PATH}.tmp2" "$PLIST_PATH"
    rm -f "${PLIST_PATH}.tmp1" "$INSERT_BLOCK"
  else
    rm -f "${PLIST_PATH}.tmp1" "${PLIST_PATH}.tmp2" "$INSERT_BLOCK"
    osascript -e 'display dialog "❌ Failed to update LaunchAgent plist properly." buttons {"OK"}'
    continue
  fi

  launchctl unload "$PLIST_PATH" 2>/dev/null
  launchctl load "$PLIST_PATH"

  osascript -e 'display dialog "✅ Sync times updated and schedule reloaded!" buttons {"OK"}'
  continue
fi
# ========= Install SwiftBar Plugin =========
if [[ "$MODE" == "Install SwiftBar Plugin" ]]; then
  SWIFTBAR_PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
  if [ ! -d "$SWIFTBAR_PLUGIN_DIR" ]; then
    osascript -e 'display dialog "⚠️ SwiftBar not found.\nPlease install SwiftBar from https://swiftbar.app and run it once." buttons {"OK"}'
    continue
  fi

  PLUGIN_SRC="$APP_RESOURCES_PATH/berd_sync.1m.sh"
  PLUGIN_DEST="$SWIFTBAR_PLUGIN_DIR/berd_sync.1m.sh"

  # Replace __HOME__ with actual path
  sed "s|__HOME__|$HOME|g" "$PLUGIN_SRC" > "$PLUGIN_DEST"
  chmod +x "$PLUGIN_DEST"

  osascript -e 'display dialog "✅ SwiftBar plugin installed!\nYou may need to enable it in SwiftBar." buttons {"OK"}'
  continue
fi
done