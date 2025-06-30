#!/bin/bash

# Get the Linux username
USERNAME=$(whoami)

# Convert the first argument (Windows path) to a Linux path
WIN_PATH="$1"
LINUX_PATH=$(winepath -u "$WIN_PATH" 2>/dev/null | head -n1)

# Debug log (optional)
echo "Intercepted path: $WIN_PATH -> $LINUX_PATH" >> "$HOME/wine_path_redirect.log"

# Target Roblox screenshots folder
TARGET_PREFIX="/home/$USERNAME/Pictures/Novarin Screenshots"

# Check for Roblox screenshots path match
if [[ "$LINUX_PATH" == "/home/$USERNAME/Pictures/Roblox/"* ]]; then
    # Extract filename (after .../Roblox/)
    REL_PATH="${LINUX_PATH#/home/$USERNAME/Pictures/Roblox/}"
    
    # Build new path
    REDIRECT_PATH="$TARGET_PREFIX/$REL_PATH"
    
    # Open the redirected path
    xdg-open "$REDIRECT_PATH"
else
    # If not matching, fall back to original explorer
    truepath="${2%?}"
    unixpath="$(printf '%s\n' "$truepath" | sed -e 's/\\/\//g' -e 's/^.://'; echo x)"
    unixpath="${unixpath%?x}"
    xdg-open "$unixpath"
fi
