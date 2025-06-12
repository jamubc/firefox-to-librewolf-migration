#!/bin/bash

# Firefox to LibreWolf Migration Script for macOS
# This script migrates Firefox data to LibreWolf without deleting Firefox data
# https://github.com/jamubc/firefox-to-librewolf-migration

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Firefox to LibreWolf Migration Tool ===${NC}"
echo -e "Version: 1.0.0"
echo

# Define paths
FIREFOX_SUPPORT="$HOME/Library/Application Support/Firefox"
LIBREWOLF_SUPPORT="$HOME/Library/Application Support/librewolf"
BACKUP_DIR="$HOME/Desktop/Firefox-to-LibreWolf-Migration-$(date +%Y%m%d-%H%M%S)"

# Check if Firefox is installed
if [ ! -d "$FIREFOX_SUPPORT" ]; then
    echo -e "${RED}Error: Firefox doesn't appear to be installed.${NC}"
    echo "Firefox support directory not found at: $FIREFOX_SUPPORT"
    exit 1
fi

# Check if LibreWolf is installed
if [ ! -d "$LIBREWOLF_SUPPORT" ]; then
    echo -e "${RED}Error: LibreWolf doesn't appear to be installed.${NC}"
    echo "LibreWolf support directory not found at: $LIBREWOLF_SUPPORT"
    echo
    echo "Please install LibreWolf first:"
    echo "  brew install --cask librewolf"
    exit 1
fi

# Ensure Firefox and LibreWolf are not running
echo -e "${YELLOW}Checking if Firefox is running...${NC}"
if pgrep -x "Firefox" > /dev/null; then
    echo -e "${RED}Firefox is running. Please close it and run this script again.${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking if LibreWolf is running...${NC}"
if pgrep -x "LibreWolf" > /dev/null; then
    echo -e "${RED}LibreWolf is running. Please close it and run this script again.${NC}"
    exit 1
fi

# List available Firefox profiles
echo -e "${YELLOW}Detecting Firefox profiles...${NC}"
if [ ! -d "$FIREFOX_SUPPORT/Profiles" ]; then
    echo -e "${RED}No Firefox profiles found!${NC}"
    exit 1
fi

# Get list of profiles
PROFILES=()
while IFS= read -r -d '' profile; do
    PROFILES+=("$(basename "$profile")")
done < <(find "$FIREFOX_SUPPORT/Profiles" -maxdepth 1 -mindepth 1 -type d -print0)

if [ ${#PROFILES[@]} -eq 0 ]; then
    echo -e "${RED}No Firefox profiles found!${NC}"
    exit 1
fi

# Select profile to migrate
if [ ${#PROFILES[@]} -eq 1 ]; then
    FIREFOX_PROFILE="${PROFILES[0]}"
    echo -e "${GREEN}Found one profile: $FIREFOX_PROFILE${NC}"
else
    echo -e "${GREEN}Found ${#PROFILES[@]} profiles:${NC}"
    for i in "${!PROFILES[@]}"; do
        echo "  $((i+1)). ${PROFILES[$i]}"
    done
    
    while true; do
        read -p "Select profile to migrate (1-${#PROFILES[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#PROFILES[@]} ]; then
            FIREFOX_PROFILE="${PROFILES[$((selection-1))]}"
            break
        else
            echo -e "${RED}Invalid selection. Please try again.${NC}"
        fi
    done
fi

FIREFOX_PROFILE_PATH="$FIREFOX_SUPPORT/Profiles/$FIREFOX_PROFILE"
echo -e "${GREEN}Selected profile: $FIREFOX_PROFILE${NC}"

# Create backup directory
echo -e "${YELLOW}Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"

# Backup current LibreWolf profiles
echo -e "${YELLOW}Backing up existing LibreWolf profiles...${NC}"
if [ -d "$LIBREWOLF_SUPPORT/Profiles" ]; then
    cp -R "$LIBREWOLF_SUPPORT/Profiles" "$BACKUP_DIR/LibreWolf-Profiles-Backup"
    echo -e "${GREEN}✓ LibreWolf profiles backed up${NC}"
fi

# Create new LibreWolf profile name
NEW_PROFILE_NAME="firefox-migrated-$(date +%Y%m%d%H%M%S)"
NEW_PROFILE_DIR="$LIBREWOLF_SUPPORT/Profiles/$NEW_PROFILE_NAME"

# Copy Firefox profile to LibreWolf
echo -e "${YELLOW}Copying Firefox profile data to LibreWolf...${NC}"
mkdir -p "$NEW_PROFILE_DIR"

# List of important files and folders to copy
ITEMS_TO_COPY=(
    "places.sqlite"              # Bookmarks and history
    "favicons.sqlite"            # Favicon cache
    "key4.db"                    # Password encryption key
    "logins.json"                # Saved passwords
    "cookies.sqlite"             # Cookies
    "permissions.sqlite"         # Site permissions
    "formhistory.sqlite"         # Form data
    "webappsstore.sqlite"        # Local storage
    "storage"                    # IndexedDB and other storage
    "sessionstore.jsonlz4"       # Open tabs and windows
    "prefs.js"                   # User preferences
    "user.js"                    # User overrides (if exists)
    "search.json.mozlz4"         # Search engines
    "extensions"                 # Extensions folder
    "extension-preferences.json" # Extension settings
    "extension-settings.json"    # Extension settings
    "addons.json"               # Addon metadata
    "extensions.json"           # Extension list
    "mimeTypes.rdf"             # File type associations (old Firefox)
    "handlers.json"             # Protocol handlers
    "cert9.db"                  # Security certificates
    "credentialstate.sqlite"    # Credentials
    "protections.sqlite"        # Tracking protection
    "content-prefs.sqlite"      # Site-specific preferences
    "chromecustomizations"      # UI customizations
    "bookmarkbackups"           # Bookmark backups folder
)

# Copy each item if it exists
COPIED_COUNT=0
for item in "${ITEMS_TO_COPY[@]}"; do
    if [ -e "$FIREFOX_PROFILE_PATH/$item" ]; then
        echo -e "  Copying: $item"
        cp -R "$FIREFOX_PROFILE_PATH/$item" "$NEW_PROFILE_DIR/" 2>/dev/null || true
        ((COPIED_COUNT++))
    fi
done

# Also copy any .sqlite-wal and .sqlite-shm files (WAL mode files)
echo -e "  Copying database transaction files..."
find "$FIREFOX_PROFILE_PATH" -maxdepth 1 \( -name "*.sqlite-wal" -o -name "*.sqlite-shm" \) | while read -r file; do
    cp "$file" "$NEW_PROFILE_DIR/" 2>/dev/null || true
done

# Copy any personal dictionary files
find "$FIREFOX_PROFILE_PATH" -maxdepth 1 -name "personalDictionary-*.dic" | while read -r file; do
    cp "$file" "$NEW_PROFILE_DIR/" 2>/dev/null || true
done

echo -e "${GREEN}✓ Copied $COPIED_COUNT items from Firefox profile${NC}"

# Update LibreWolf profiles.ini
echo -e "${YELLOW}Updating LibreWolf profile configuration...${NC}"

# Backup current profiles.ini
cp "$LIBREWOLF_SUPPORT/profiles.ini" "$BACKUP_DIR/librewolf-profiles.ini.backup"

# Get the next profile number
PROFILE_COUNT=$(grep -c "^\[Profile[0-9]\+\]" "$LIBREWOLF_SUPPORT/profiles.ini" 2>/dev/null || echo "0")

# Add the new profile to profiles.ini
cat >> "$LIBREWOLF_SUPPORT/profiles.ini" << EOF

[Profile$PROFILE_COUNT]
Name=Firefox Migrated $(date +%Y-%m-%d)
IsRelative=1
Path=Profiles/$NEW_PROFILE_NAME

EOF

echo -e "${GREEN}✓ Profile configuration updated${NC}"

# Clean up LibreWolf-specific files that might conflict
echo -e "${YELLOW}Cleaning up incompatible files...${NC}"
rm -f "$NEW_PROFILE_DIR/times# Clean up LibreWolf-specific files that might conflict
echo -e "${YELLOW}Cleaning up incompatible files...${NC}"
rm -f "$NEW_PROFILE_DIR/times.json" 2>/dev/null || true
rm -f "$NEW_PROFILE_DIR/.parentlock" 2>/dev/null || true
rm -f "$NEW_PROFILE_DIR/parent.lock" 2>/dev/null || true
rm -f "$NEW_PROFILE_DIR/lock" 2>/dev/null || true

# Create a prefs cleanup file to ensure compatibility
echo -e "${YELLOW}Creating preference cleanup file...${NC}"
cat > "$NEW_PROFILE_DIR/user-overrides.js" << 'EOF'
// Firefox to LibreWolf Migration - User Overrides
// These settings ensure compatibility after migration

// Reset any Firefox-specific paths
user_pref("browser.download.lastDir", "");
user_pref("browser.open.lastDir", "");

// Ensure LibreWolf privacy settings are applied
user_pref("privacy.resistFingerprinting", true);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.sessions", false);
user_pref("network.cookie.lifetimePolicy", 0);

// Disable automatic updates (LibreWolf handles this differently)
user_pref("app.update.auto", false);
EOF

# Create migration report
echo -e "${YELLOW}Creating migration report...${NC}"
cat > "$BACKUP_DIR/migration-report.txt" << EOF
Firefox to LibreWolf Migration Report
=====================================
Date: $(date)
Source Firefox Profile: $FIREFOX_PROFILE
Destination LibreWolf Profile: $NEW_PROFILE_NAME
Backup Location: $BACKUP_DIR

Items Migrated:
- Bookmarks and browsing history
- Saved passwords and logins
- Cookies and site data
- Extensions and their settings
- Form autofill data
- Download history
- Search engines
- Site permissions
- Security certificates
- Custom preferences

Next Steps:
1. Launch LibreWolf
2. Select "Firefox Migrated $(date +%Y-%m-%d)" profile if prompted
3. Verify all your data is present
4. Sign into Firefox Sync if desired (Note: LibreWolf may have Sync disabled)
5. Check that all extensions are working

Important Notes:
- Some Firefox-specific extensions may need to be reinstalled
- LibreWolf has enhanced privacy settings that may affect some sites
- Your original Firefox data remains untouched

If you need to revert:
- Your original Firefox data is untouched
- LibreWolf backup is in: $BACKUP_DIR/LibreWolf-Profiles-Backup
EOF

echo -e "${GREEN}✓ Migration report created${NC}"

# Set permissions
echo -e "${YELLOW}Setting proper permissions...${NC}"
chmod -R 700 "$NEW_PROFILE_DIR"

# Display summary
echo
echo -e "${GREEN}=== Migration Completed Successfully! ===${NC}"
echo
echo -e "${BLUE}Summary:${NC}"
echo "• Profile migrated: $FIREFOX_PROFILE"
echo "• New LibreWolf profile: $NEW_PROFILE_NAME"
echo "• Backup location: $BACKUP_DIR"
echo "• Items copied: $COPIED_COUNT"
echo
echo -e "${YELLOW}Important Notes:${NC}"
echo "1. Your Firefox data has been copied to LibreWolf (Firefox data is untouched)"
echo "2. When you launch LibreWolf, you may need to select the migrated profile"
echo "3. Some Firefox-specific extensions may need to be reinstalled"
echo "4. LibreWolf has stricter privacy settings which may affect some websites"
echo
echo -e "${GREEN}You can now launch LibreWolf to verify the migration!${NC}"
echo
echo "To launch LibreWolf:"
echo "  • From Terminal: librewolf"
echo "  • From Finder: Applications → LibreWolf"
echo "  • From Spotlight: Cmd+Space, type 'LibreWolf'"
