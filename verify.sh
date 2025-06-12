#!/bin/bash

# LibreWolf Migration Verification Script
# Verifies that Firefox data was successfully migrated to LibreWolf

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== LibreWolf Migration Verification ===${NC}"
echo

LIBREWOLF_SUPPORT="$HOME/Library/Application Support/librewolf"
FIREFOX_SUPPORT="$HOME/Library/Application Support/Firefox"

# Check if LibreWolf support directory exists
if [ ! -d "$LIBREWOLF_SUPPORT" ]; then
    echo -e "${RED}Error: LibreWolf support directory not found.${NC}"
    echo "Expected location: $LIBREWOLF_SUPPORT"
    exit 1
fi

# Find migrated profiles
echo -e "${YELLOW}Looking for migrated profiles...${NC}"
MIGRATED_PROFILES=()

if [ -d "$LIBREWOLF_SUPPORT/Profiles" ]; then
    while IFS= read -r -d '' profile; do
        if [[ "$(basename "$profile")" == firefox-migrated-* ]]; then
            MIGRATED_PROFILES+=("$(basename "$profile")")
        fi
    done < <(find "$LIBREWOLF_SUPPORT/Profiles" -maxdepth 1 -mindepth 1 -type d -print0)
fi

if [ ${#MIGRATED_PROFILES[@]} -eq 0 ]; then
    echo -e "${RED}No migrated profiles found.${NC}"
    echo "Please run the migration script first."
    exit 1
fi

# Select profile to verify
if [ ${#MIGRATED_PROFILES[@]} -eq 1 ]; then
    PROFILE_TO_CHECK="${MIGRATED_PROFILES[0]}"
    echo -e "${GREEN}Found migrated profile: $PROFILE_TO_CHECK${NC}"
else
    echo -e "${GREEN}Found ${#MIGRATED_PROFILES[@]} migrated profiles:${NC}"
    for i in "${!MIGRATED_PROFILES[@]}"; do
        echo "  $((i+1)). ${MIGRATED_PROFILES[$i]}"
    done
    
    while true; do
        read -p "Select profile to verify (1-${#MIGRATED_PROFILES[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#MIGRATED_PROFILES[@]} ]; then
            PROFILE_TO_CHECK="${MIGRATED_PROFILES[$((selection-1))]}"
            break
        else
            echo -e "${RED}Invalid selection. Please try again.${NC}"
        fi
    done
fi

PROFILE_PATH="$LIBREWOLF_SUPPORT/Profiles/$PROFILE_TO_CHECK"

# Check key files
echo -e "\n${YELLOW}Checking migrated data:${NC}"

FILES_TO_CHECK=(
    "places.sqlite"              "Bookmarks and history"
    "key4.db"                    "Password encryption key"
    "logins.json"                "Saved passwords"
    "cookies.sqlite"             "Cookies"
    "extensions"                 "Extensions folder"
    "formhistory.sqlite"         "Form data"
    "permissions.sqlite"         "Site permissions"
    "cert9.db"                   "Security certificates"
    "sessionstore.jsonlz4"       "Session data"
    "prefs.js"                   "User preferences"
)

FOUND_COUNT=0
MISSING_COUNT=0

i=0
while [ $i -lt ${#FILES_TO_CHECK[@]} ]; do
    file="${FILES_TO_CHECK[$i]}"
    desc="${FILES_TO_CHECK[$((i+1))]}"
    
    if [ -e "$PROFILE_PATH/$file" ]; then
        # Get file size
        if [ -d "$PROFILE_PATH/$file" ]; then
            size=$(du -sh "$PROFILE_PATH/$file" 2>/dev/null | cut -f1)
        else
            size=$(ls -lh "$PROFILE_PATH/$file" 2>/dev/null | awk '{print $5}')
        fi
        echo -e "  ${GREEN}✓${NC} $desc ($size)"
        ((FOUND_COUNT++))
    else
        echo -e "  ${YELLOW}⚠${NC} $desc (not found)"
        ((MISSING_COUNT++))
    fi
    
    i=$((i+2))
done

# Check profile size
echo -e "\n${YELLOW}Profile size information:${NC}"
if [ -d "$PROFILE_PATH" ]; then
    PROFILE_SIZE=$(du -sh "$PROFILE_PATH" 2>/dev/null | cut -f1)
    echo -e "  LibreWolf migrated profile size: ${GREEN}$PROFILE_SIZE${NC}"
fi

# Count extensions
if [ -d "$PROFILE_PATH/extensions" ]; then
    EXT_COUNT=$(find "$PROFILE_PATH/extensions" -name "*.xpi" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  Extensions found: ${GREEN}$EXT_COUNT${NC}"
fi

# Check if profile is registered
echo -e "\n${YELLOW}Profile registration:${NC}"
if grep -q "$PROFILE_TO_CHECK" "$LIBREWOLF_SUPPORT/profiles.ini" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Profile is registered in LibreWolf"
    
    # Get profile name from profiles.ini
    PROFILE_NAME=$(grep -A2 "$PROFILE_TO_CHECK" "$LIBREWOLF_SUPPORT/profiles.ini" | grep "^Name=" | cut -d'=' -f2-)
    if [ -n "$PROFILE_NAME" ]; then
        echo -e "  Profile name: ${GREEN}$PROFILE_NAME${NC}"
    fi
else
    echo -e "  ${RED}✗${NC} Profile not found in profiles.ini"
fi

# Summary
echo -e "\n${BLUE}=== Verification Summary ===${NC}"
echo -e "Profile: $PROFILE_TO_CHECK"
echo -e "Items found: ${GREEN}$FOUND_COUNT${NC}"
if [ $MISSING_COUNT -gt 0 ]; then
    echo -e "Items missing: ${YELLOW}$MISSING_COUNT${NC} (this may be normal)"
fi

if [ $FOUND_COUNT -gt 5 ]; then
    echo -e "\n${GREEN}✓ Migration appears successful!${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Launch LibreWolf"
    echo "2. Select the migrated profile if prompted"
    echo "3. Verify your bookmarks, passwords, and extensions"
    echo "4. Check that your preferred settings are intact"
else
    echo -e "\n${RED}⚠ Migration may be incomplete.${NC}"
    echo "Please check the migration logs or try running the migration again."
fi

# Check for common issues
echo -e "\n${YELLOW}Checking for common issues:${NC}"

# Check if Firefox is still running
if pgrep -x "Firefox" > /dev/null; then
    echo -e "  ${YELLOW}⚠${NC} Firefox is currently running"
    echo "     This won't affect the migrated data, but close it before re-migrating"
else
    echo -e "  ${GREEN}✓${NC} Firefox is not running"
fi

# Check if LibreWolf is running
if pgrep -x "LibreWolf" > /dev/null; then
    echo -e "  ${YELLOW}⚠${NC} LibreWolf is currently running"
    echo "     You may need to restart it to see the migrated profile"
else
    echo -e "  ${GREEN}✓${NC} LibreWolf is not running"
fi
