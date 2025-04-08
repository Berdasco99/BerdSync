#!/bin/bash

CONFIG="$HOME/Library/Application Support/BerdSync/config.json"
LOG="$HOME/sync_debug.log"
SYNC_SCRIPT="$HOME/Library/Application Support/BerdSync/sync.sh"
APP_PATH="/Applications/BerdSync.app"
JQ="$HOME/Library/Application Support/BerdSync/jq"

NOW=$(date +%s)
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date -v+1d +%Y-%m-%d)

# Fetch sync times
FIRST_SYNC=$("$JQ" -r '.syncTimes.firstSyncTime // "10:00 AM"' "$CONFIG" 2>/dev/null)
SECOND_SYNC=$("$JQ" -r '.syncTimes.secondSyncTime // "10:00 PM"' "$CONFIG" 2>/dev/null)

SYNC1=$(date -j -f "%Y-%m-%d %I:%M %p" "$TODAY $FIRST_SYNC" +%s 2>/dev/null)
SYNC2=$(date -j -f "%Y-%m-%d %I:%M %p" "$TODAY $SECOND_SYNC" +%s 2>/dev/null)

if [ $NOW -lt $SYNC1 ]; then
  NEXT_SYNC=$SYNC1
elif [ $NOW -lt $SYNC2 ]; then
  NEXT_SYNC=$SYNC2
else
  NEXT_SYNC=$(date -j -f "%Y-%m-%d %I:%M %p" "$TOMORROW $FIRST_SYNC" +%s)
fi

REMAINING=$((NEXT_SYNC - NOW))
format_time() {
  local T=$1
  local H=$((T / 3600))
  local M=$(((T % 3600) / 60))
  local S=$((T % 60))
  printf "%02dh %02dm %02ds" $H $M $S
}
COUNTDOWN=$(format_time $REMAINING)

LAST_SYNC=$(grep "Sync finished at" "$LOG" | tail -n 1 | sed 's/.*Sync finished at //')
ICON="✅"

if [ -z "$LAST_SYNC" ]; then
  ICON="❓"
elif ! date -j -f "%a %b %e %T %Z %Y" "$LAST_SYNC" +%s >/dev/null 2>&1; then
  ICON="❓"
else
  LAST_TIME=$(date -j -f "%a %b %e %T %Z %Y" "$LAST_SYNC" +%s)
  if [ $((NOW - LAST_TIME)) -gt 43200 ]; then
    ICON="⚠️"
  fi
fi

# === SwiftBar Output ===
echo "$ICON BerdSync"
echo "---"
echo "🕒 Last Sync: $LAST_SYNC"
echo "⏳ Next Sync In: $COUNTDOWN"
echo "---"
echo "📄 Open Log | terminal=false bash=open param1=\"$LOG\""
echo "🔄 Run Sync Now | terminal=false bash=\"$SYNC_SCRIPT\" refresh=true"
echo "⚙️ Open BerdSync App | terminal=false bash=open param1=-a param2=\"BerdSync\" refresh=true"
echo "---"
echo "ℹ️ [DEBUG] Plugin refreshed at $(date)"
echo "[DEBUG] Plugin refreshed at $(date)" >> "$LOG"
