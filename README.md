# BerdSync

**BerdSync** is a lightweight macOS utility that syncs your Obsidian vault (or any folder) between two destinations — such as Google Drive and iCloud — while keeping automatic backups of deleted or modified files.

I originally made this app for myself but since I thought it could be useful for other people I decide to create a full fledged app, just make a folder that contains everything you want to backup and enjoy!

---

## Features

- **Two-Way Syncing**  
  Automatically syncs files from one folder to another using `rsync`.

- **Backup of Deleted & Modified Files**  
  Maintains timestamped backups of every change in a structured archive.

- **Scheduled Automatic Sync**  
  Runs twice daily by default (10:00 AM and 10:00 PM) via a macOS LaunchAgent. Sync times are fully customizable from the app menu.

- **Backup Retention Control**  
  Automatically removes backups older than your selected limit — or retains them all forever.

- **Manual Sync Option**  
  Run the sync at any time from the app or from the menu bar using the SwiftBar plugin.

- **SwiftBar Integration (Optional)**  
  Adds a menu bar widget showing sync status and last run time, and allows on-demand syncing.

---

## Getting Started

1. **Install the App**
   - Download the `.dmg` file.
   - Drag `BerdSync.app` to your **Applications** folder.
   - Launch the app once to complete setup.
   - If macOS blocks it, you can bypass Gatekeeper by running:

     ```bash
     xattr -d com.apple.quarantine /Applications/BerdSync.app
     ```

2. **Choose Your Folders**
   - Main Folder: typically your Obsidian vault (e.g., Google Drive).
   - Backup Folder: destination for synced data and versioned backups (e.g., iCloud).

3. **Set Backup Retention**
   - Define how many days of backups to keep.
   - Set to `0` to retain all backups indefinitely.

4. **Enable Automatic Sync**
   - BerdSync installs a LaunchAgent to handle background syncing on a schedule.
   - Edit sync times directly from the app menu.

5. **(Optional) Install the SwiftBar Plugin**
   - From the app menu, choose "Install SwiftBar Plugin."
   - Requires [SwiftBar](https://swiftbar.app) to be installed separately.

---

## Technologies Used

- [**Platypus**](https://github.com/sveinbjornt/Platypus) — used to package the bash-based app into a native `.app` bundle with a custom icon and interactive menu.
- [**AppleScript**](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/introduction/ASLR_intro.html) — powers the app’s menu system, dialog windows, and interface logic.
- [**Bash**](https://www.gnu.org/software/bash/) — handles core functionality, preferences, syncing, and scheduling logic.
- [**rsync**](https://github.com/WayneD/rsync) — efficiently synchronizes files and directories.
- [**jq**](https://github.com/stedolan/jq) — processes the configuration stored in JSON format.
- [**LaunchAgents**](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html) — schedule and run sync tasks in the background.
- [**SwiftBar**](https://github.com/swiftbar/SwiftBar) *(optional)* — enables sync controls and status in the macOS menu bar.

---

## Permissions Required

To function correctly with Google Drive, iCloud, and other user folders, BerdSync requires **Full Disk Access**.

Go to:  
**System Settings > Privacy & Security > Full Disk Access**  
Add `BerdSync.app` manually if it isn’t listed.

---

## How It Works

- Syncs files using `rsync`, ensuring speed and file integrity.
- Detects deletions and overwrites, and archives affected files before proceeding.
- Saves configuration settings to a JSON file within the user environment.
- Sets up and manages a macOS LaunchAgent for scheduled syncing.
- User interface and logic are handled through AppleScript and Bash, bundled into a native `.app` using Platypus.

---

## Credits

Created by [@berdasco](https://github.com/Berdasco99)

You can download BerdSync from the [GitHub releases page](https://github.com/Berdasco99/BerdSync/releases).

---

## License

**MIT License** — free and open-source.

**Included Utilities**  
BerdSync includes the `jq` command-line utility, licensed under the MIT License.  
See the [jq GitHub repository](https://github.com/stedolan/jq) for details.
