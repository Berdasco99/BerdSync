BerdSync – README

---

Overview

BerdSync is a lightweight macOS utility that automatically syncs your Obsidian vault between two folders of your choice (ideally Google Drive and iCloud), while keeping time-stamped backups of deleted or modified notes. It includes automatic scheduling, manual sync options, and a SwiftBar plugin for quick access.

Originally put together in a single night without sleep (classic dev story), I ended up feeling like this could be useful for more people so I set out to develop my first ever app, if it sucks that's why lol.

---

Getting Started

1. Choose Your Folders for Sync
   - BerdSync works with any two folders (so even tho I made this to make copies of obsidian vaults you could technically use it as a glorified copy paste tool).
   - Best setup: Google Drive for your vault, iCloud for backups.
   - To set up:
     - Main Folder (your Obsidian vault): e.g., /Users/yourname/Google Drive/ObsidianVault
     - Backup Folder: e.g., /Users/yourname/Library/Mobile Documents/com~apple~CloudDocs/ZettelkastenBackups

2. Set Your Preferences
   - Open BerdSync and select Edit Preferences.
   - Enter the full paths for the folders you want to sync and back up.
   - You'll also be prompted to choose a backup retention period.

3. Choose a Backup Retention Period
   - BerdSync stores backups of files that are modified or deleted.
   - Set how many days to keep backups (or 0 to keep them forever).

---

Automatic Sync

- BerdSync installs a LaunchAgent to sync your folders twice daily.
- Default schedule: 10:00 AM and 10:00 PM
- You can change these times from within the app under Edit Automatic Sync Times.
- The process runs silently in the background.

---

Manual Sync & SwiftBar Plugin

- You can also run a sync anytime using:
  - The "Sync Now" option in the BerdSync app.
  - The SwiftBar plugin, if installed.

SwiftBar Plugin Features:
- Displays last sync time and time until next scheduled sync.
- One-click access to logs, the sync process, and the app itself.
- Optional but highly recommended for convenience.

---

Backup Behavior

- Each time a sync runs:
  - Any files that are deleted or overwritten are backed up to:
    BACKUP_FOLDER/file_backups/YYYY-MM-DD/HH-MM-SS/
  - Backups are cleaned up based on your chosen retention period, if you choose 30 days the folders in your backup folder will survive for 30 days and then be automatically deleted by the app.

---

Permissions

To ensure BerdSync can access all required folders:

1. Go to System Settings > Privacy & Security > Full Disk Access
2. Add the BerdSync app to the list.
3. Restart the app for changes to take effect.

---

Logs & Debugging

- All sync actions are logged to:
  ~/sync_debug.log
- If something goes wrong, check this file for details.

---

Special Thanks

- Luis: For sleeping next to me while I coded. Impeccable moral support.
- The Other Luis: For letting me spam updates at 3AM and not muting me.
- My dog Pipa: 10/10 best dog, no notes.

---

Nerd Stuff

- BerdSync bundles jq internally, so it works out of the box.
- No wrappers needed. All logic is contained and managed inside the app.
- Includes a built-in installer for the SwiftBar plugin.

---

Special Thanks

- Luis: For sleeping behind me while I coded. Your unconscious moral support was unmatched.
- The Other Luis: For being spammed with status updates on WhatsApp and not blocking me.
- My dog Pipa: She is awesome.

---

Final Notes

BerdSync is open source and free.
- No tracking.
- No telemetry.
- No BS.

GitHub: https://github.com/yourusername/berdsync  
Enjoy, and if it makes your note-taking life easier — let me know. That’d be cool.

– berdasco