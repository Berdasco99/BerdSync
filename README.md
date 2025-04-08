# BerdSync

**BerdSync** is a lightweight macOS utility that syncs your Obsidian vault (or any folder) between two destinations — like Google Drive and iCloud — while keeping automatic backups of deleted or modified notes.

Perfect for note-takers who want automatic syncing and version control with minimal setup.

---

## Features

- **Two-Way Syncing**  
  Automatically syncs files from one folder into another.

- **Backup of Deleted & Modified Files**  
  Keeps timestamped backups of every change in a structured folder.

- **Customizable Automatic Sync**  
  Sync runs twice daily (default: 10:00 AM and 10:00 PM) using a LaunchAgent.

- **Retention Control**  
  Automatically deletes backups older than your defined period — or keeps everything forever.

- **Manual Sync Option**  
  Trigger sync anytime from the app or SwiftBar menu.

- **SwiftBar Plugin Support (Optional)**  
  View sync status, last run time, and run sync manually from your macOS menu bar.

---

## Getting Started

1. **Install the App**
   - Download the `.dmg` file.
   - Drag `BerdSync.app` to your **Applications** folder.
   - Launch it once to complete setup.
   - Apple may not let you open my app, you can use this to bypass that:
```bash
xattr -d com.apple.quarantine /Applications/BerdSync.app
```

2. **Choose Your Folders**
   - Main Folder: your Obsidian vault (e.g., Google Drive)
   - Backup Folder: where sync results and backups go (e.g., iCloud)

3. **Set a Retention Period**
   - Choose how many days of backups to keep.
   - Set to `0` to keep everything forever.

4. **Enable Auto-Sync**
   - BerdSync sets up a LaunchAgent that runs the sync script twice per day.
   - Times are customizable from the app menu.

5. **(Optional) Install SwiftBar Plugin**
   - Choose "Install SwiftBar Plugin" from the app menu.
   - Requires [SwiftBar](https://swiftbar.app) to be installed.

---

## Permissions Required

To work correctly with iCloud and external folders, **BerdSync requires Full Disk Access**.

Grant access here:
- **System Settings > Privacy & Security > Full Disk Access**
- Add `BerdSync.app` manually if not already present.

---

## How It Works

- Uses `rsync` to detect and copy changes efficiently.
- Creates backups before overwriting or deleting anything.
- LaunchAgent handles automatic scheduled syncs.
- Configuration is saved at your specified location.
- Interface is powered by AppleScript + Bash.

---

## Credits

Made by [@berdasco](https://github.com/Berdasco99)  

---

# You can download in [releases](https://github.com/Berdasco99/BerdSync/releases).

## License

MIT License — free
