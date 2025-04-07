Sync Zettelkasten – README

Overview

Sync Zettelkasten is a macOS utility that automatically syncs your Obsidian vault between 2 folders of your choice (ideally Drive and iCloud) while keeping a version-controlled backup of deleted or modified notes.

This app was built in a single night without sleep (classic), so don’t expect perfection — but it works well, I hope lol.

I made it because I couldn't find a tool that did this thing in the 5 minutes I spent browsing so I built one. Enjoy!

---

Getting the Most Out of Sync Zettelkasten:

1. **Choose Your Folders for Sync**
   - Select the folders you want to sync — the app works with **any folders** you choose.
   - For **optimal safety**, it's recommended to use **Google Drive** for your Obsidian vault and **iCloud** for backups or viceversa. These cloud services ensure that your files are synced and version-controlled, with an extra layer of protection.
   - To set up:
     - **For Obsidian Vault**: Move your vault to a folder on Google Drive or another cloud service.
     - **For Backups**: Pick a folder on iCloud Drive to store your backups and versioned files.

2. **Set Up Your Folders in Preferences**
   - Open **Sync Zettelkasten** and go to *Edit Preferences*.
   - Paste the **full path** of your chosen folders, they should look something like this:
     - Your Obsidian folder (e.g., **Google Drive** folder /Users/yourname/Google Drive/your-email@gmail.com/ObsidianVault)
     - Your backup folder (e.g., **iCloud** folder Users/yourname/Library/Mobile Documents/com~apple~CloudDocs/ZettelkastenBackups)

3. **Choose Your Backup Retention Period**
   - The app will ask how long you want to keep old backups.
   - For example, if you set “30” days, backups older than that will be automatically deleted to save space.

4. **Automatic Sync Setup**
   - **Sync Zettelkasten** will automatically sync your files at **10:00 AM** and **10:00 PM** every day.
   - The app installs a background process that ensures this happens, so you don't need to worry about it.
   - You can also trigger a manual sync directly from the app or through the SwiftBar plugin.

5. **Optional: Add the SwiftBar Plugin for Quick Access**
   - If you use [SwiftBar](https://swiftbar.app), you can install the plugin from within the app.
   - It provides an easy way to view the last sync time, check the next scheduled sync, and quickly trigger sync or open the logs directly from the menu bar.
   - For the **best experience**, I recommend using the app alongside SwiftBar for easy access to sync details.

---

What Gets Backed Up?

Every time the app runs:
- Deleted notes are stored in `deleted_zettels/YYYY-MM-DD/HH-MM-SS/`
- You’ll always have a time-stamped backup of deleted files.
- Older backups are automatically cleaned up based on your retention settings.

---

Special Thanks

- **Luis**: For sleeping behind me while I coded. Your unconscious moral support was unmatched.
- **The Other Luis**: For being spammed with status updates on WhatsApp and not blocking me.
- **My dog Pipa**: She is awesome.

---

Final Notes

This app is open source and free. No tracking, no nonsense.
Check out the GitHub: https://github.com/yourusername/sync-zettelkasten

Enjoy it, and let me know if it made your note-taking life easier, It'd mean a lot to me.

– berdasco
