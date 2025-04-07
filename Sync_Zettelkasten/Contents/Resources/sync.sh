#!/bin/bash

# Fallback APP_RESOURCES_PATH if not set or invalid
if [ -z "$APP_RESOURCES_PATH" ] || [ ! -f "$APP_RESOURCES_PATH/jq" ]; then
  APP_RESOURCES_PATH="$HOME/Library/Application Support/SyncZettelkasten"
fi
JQ="$APP_RESOURCES_PATH/jq"
CONFIG_FILE="$HOME/Library/Application Support/SyncZettelkasten/config.json"
LOG="$HOME/sync_debug.log"

# === Debug ===
echo "sync.sh started at $(date)" >> "$LOG"
echo "Using config: $CONFIG_FILE" >> "$LOG"
echo "Using jq: $JQ" >> "$LOG"

if [ ! -x "$JQ" ]; then
  echo "❌ jq not found or not executable at $JQ" >> "$LOG"
  exit 1
fi

# Exit if no config
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ No config file found." >> "$LOG"
  exit 1
fi

GOOGLE_DRIVE_PATH=$("$JQ" -r '.googleDrivePath' "$CONFIG_FILE")
ICLOUD_PATH=$("$JQ" -r '.icloudPath' "$CONFIG_FILE")
BACKUP_RETENTION_PERIOD=$("$JQ" -r '.backupRetentionPeriod' "$CONFIG_FILE")

RSYNC_OUTPUT=$(mktemp)
LOCKFILE="/tmp/zettelkasten_sync.lock"
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
DAYSTAMP=$(date "+%Y-%m-%d")
BACKUP_BASE="$ICLOUD_PATH/deleted_zettels/$DAYSTAMP"
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"

if [ -f "$LOCKFILE" ]; then
  echo "Another sync is already running. Exiting at $(date)." >> "$LOG"
  exit 0
fi

touch "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT

find "$BACKUP_BASE" -type d -mindepth 1 -maxdepth 1 -mtime +"$BACKUP_RETENTION_PERIOD" -exec rm -rf {} \;

echo "==== Scheduled Sync at $(date) ====" >> "$LOG"
rsync -av --backup --backup-dir="$BACKUP_DIR" \
  --delete "$GOOGLE_DRIVE_PATH" \
  "$ICLOUD_PATH" \
  | tee "$RSYNC_OUTPUT" >> "$LOG"

ADDED_MODIFIED=$(grep -vE '^sending|^sent|^total|^deleting|^\.\/$' "$RSYNC_OUTPUT" | wc -l)
DELETED=$(grep '^deleting ' "$RSYNC_OUTPUT" | wc -l)

echo "✅ Modified: $ADDED_MODIFIED | 🗑️ Deleted: $DELETED" >> "$LOG"
osascript -e "display notification \"✅ Sync complete. $ADDED_MODIFIED modified, $DELETED deleted.\" with title \"SyncZettelkasten\""

rm "$RSYNC_OUTPUT"
