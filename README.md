# Firefox to LibreWolf Migration Tool for macOS

A simple and safe tool to migrate your Firefox profile data to LibreWolf on macOS, preserving all your bookmarks, passwords, extensions, and settings.

## Features

- 🔒 **Safe Migration**: Your Firefox data remains untouched
- 📦 **Complete Transfer**: Migrates bookmarks, passwords, cookies, extensions, history, and more
- 🔄 **Automatic Backup**: Creates backups of existing LibreWolf profiles before migration
- 🎯 **Profile Selection**: Choose which Firefox profile to migrate if you have multiple
- ✅ **Verification Tool**: Verify your migration was successful
- 📝 **Detailed Reports**: Get a complete migration report with all transferred items

## What Gets Migrated

- ✅ Bookmarks and browsing history
- ✅ Saved passwords and logins
- ✅ Cookies and active sessions
- ✅ Installed extensions and their settings
- ✅ Form autofill data
- ✅ Download history
- ✅ Custom search engines
- ✅ Site permissions and preferences
- ✅ Security certificates
- ✅ User preferences and customizations

## Prerequisites

1. **macOS** (tested on macOS 11+)
2. **Firefox** installed with at least one profile
3. **LibreWolf** installed (see installation instructions below)
4. **Bash** shell (included with macOS)

## Installing LibreWolf

If you haven't installed LibreWolf yet:

```bash
# Using Homebrew
brew install --cask librewolf

# Or download from
# https://librewolf.net/
```

## Usage

### 1. Download the Scripts

```bash
# Clone this repository
git clone https://github.com/yourusername/firefox-to-librewolf-migration.git
cd firefox-to-librewolf-migration

# Or download the scripts directly
curl -O https://raw.githubusercontent.com/yourusername/firefox-to-librewolf-migration/main/migrate.sh
curl -O https://raw.githubusercontent.com/yourusername/firefox-to-librewolf-migration/main/verify.sh

# Make them executable
chmod +x migrate.sh verify.sh
```

### 2. Close Firefox and LibreWolf

Before running the migration, make sure both browsers are completely closed:

```bash
# Check if they're running
ps aux | grep -E "(Firefox|LibreWolf)" | grep -v grep

# If they are, close them through the UI or:
killall Firefox
killall LibreWolf
```

### 3. Run the Migration

```bash
./migrate.sh
```

The script will:
- Detect your Firefox profiles
- Let you choose which profile to migrate (if you have multiple)
- Create a backup of your current LibreWolf profiles
- Copy all data from Firefox to a new LibreWolf profile
- Update LibreWolf's configuration to recognize the new profile

### 4. Verify the Migration

```bash
./verify.sh
```

This will check that all important files were copied successfully.

### 5. Launch LibreWolf

After migration:
1. Open LibreWolf
2. If prompted, select the "Firefox Migrated" profile
3. Verify your bookmarks, passwords, and extensions are present
4. Sign into Firefox Sync if you use it (note: LibreWolf may have Sync disabled by default)

## File Structure

After migration, you'll find:

```
~/Desktop/Firefox-to-LibreWolf-Migration-[timestamp]/
├── LibreWolf-Profiles-Backup/    # Backup of your original LibreWolf profiles
├── librewolf-profiles.ini.backup # Backup of LibreWolf's profile configuration
└── migration-report.txt          # Detailed report of what was migrated

~/Library/Application Support/librewolf/Profiles/
└── firefox-migrated-[timestamp]/ # Your migrated Firefox profile
```

## Troubleshooting

### "Firefox/LibreWolf is running"
Make sure to completely quit both browsers before running the migration.

### Extensions not working
Some Firefox-specific extensions may need to be reinstalled from the LibreWolf add-ons store.

### Missing passwords
Ensure you migrate the profile that actually contains your saved passwords. You can check in Firefox under Settings → Privacy & Security → Saved Logins.

### Profile not showing in LibreWolf
Try launching LibreWolf with the profile manager:
```bash
librewolf -ProfileManager
```

## Reverting the Migration

Your Firefox data is never modified, so you can always go back to using Firefox.

To restore LibreWolf to its pre-migration state:
1. Close LibreWolf
2. Copy back the backup from `~/Desktop/Firefox-to-LibreWolf-Migration-*/LibreWolf-Profiles-Backup/`
3. Restore the original `profiles.ini` from the backup

## Privacy Notes

LibreWolf has enhanced privacy settings compared to Firefox:
- Resist fingerprinting is enabled by default
- Some features like Pocket and Sync may be disabled
- Telemetry is completely disabled
- DRM content may be disabled by default

These can be adjusted in LibreWolf's settings if needed.

## Contributing

Feel free to submit issues or pull requests if you encounter any problems or have suggestions for improvements.

## License

MIT License - feel free to use and modify as needed.

## Disclaimer

This tool is provided as-is. Always ensure you have backups of your important data before running migration scripts. The authors are not responsible for any data loss.
