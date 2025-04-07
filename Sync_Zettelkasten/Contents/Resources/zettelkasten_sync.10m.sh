#!/bin/bash

LOG="$HOME/sync_debug.log"
WRAPPER="$HOME/bin/run_sync_zettelkasten.sh"
APP="/Applications/SyncZettelkasten.app"

NOW=$(date +%s)
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date -v+1d +%Y-%m-%d)

SYNC1=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY 10:00" +%s 2>/dev/null)
SYNC2=$(date -j -f "%Y-%m-%d %H:%M" "$TODAY 22:00" +%s 2>/dev/null)

if [ $NOW -lt $SYNC1 ]; then
  NEXT_SYNC=$SYNC1
elif [ $NOW -lt $SYNC2 ]; then
  NEXT_SYNC=$SYNC2
else
  NEXT_SYNC=$(date -j -f "%Y-%m-%d %H:%M" "$TOMORROW 10:00" +%s)
fi

REMAINING=$((NEXT_SYNC - NOW))

# Countdown formatter
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

# SwiftBar UI
echo "$ICON Sync"
echo "---"
echo "🕒 Last Sync: $LAST_SYNC"
echo "⏳ Next Sync In: $COUNTDOWN"
echo "---"
echo "📄 Open Log | terminal=false bash=/usr/bin/open param1=$LOG"
echo "🔄 Run Sync Now | terminal=false bash=$WRAPPER"
echo "⚙️ Edit Preferences | terminal=false bash=/usr/bin/open param1=$APP"
echo "---"
echo "📝 Log tail: $(tail -n 1 $LOG)"
