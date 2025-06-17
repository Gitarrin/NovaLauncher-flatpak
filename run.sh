#!/bin/bash
export WINEPREFIX=/var/data/wine-prefix
export PATH="/app/bin:/app/lib/wine/bin:$PATH"

# Create Wine prefix if it doesn't exist
if [ ! -d "$WINEPREFIX" ]; then
    echo "Initializing Wine prefix..."
    wineboot -i
    # Additional Wine configuration can go here
fi

# Setup DXVK if not already installed
if [ ! -f "$WINEPREFIX/.dxvk_installed" ]; then
    echo "Installing DXVK..."
    # Wait for wineboot to complete
    sleep 2
    
    # Install DXVK
    WINEDLLOVERRIDES="winemenubuilder.exe=d" wineboot -u
    
    # Copy the DLLs to the system32 directory
    cp -f /app/dxvk/x32/d3d9.dll "$WINEPREFIX/drive_c/windows/system32/"
    cp -f /app/dxvk/x32/d3d10core.dll "$WINEPREFIX/drive_c/windows/system32/"
    cp -f /app/dxvk/x32/d3d11.dll "$WINEPREFIX/drive_c/windows/system32/"
    cp -f /app/dxvk/x32/d3d10.dll "$WINEPREFIX/drive_c/windows/system32/"
    cp -f /app/dxvk/x32/d3d10_1.dll "$WINEPREFIX/drive_c/windows/system32/"
    cp -f /app/dxvk/x32/dxgi.dll "$WINEPREFIX/drive_c/windows/system32/"
    
    # Mark DXVK as installed
    touch "$WINEPREFIX/.dxvk_installed"
    echo "DXVK installation complete"
fi

WINE_USER=$(find "$WINEPREFIX/drive_c/users/" -maxdepth 1 -type d | grep -v "Public\|users" | xargs basename 2>/dev/null || echo "$(whoami)")
NOVARIN_DIR="$WINEPREFIX/drive_c/users/$WINE_USER/AppData/Local/Novarin"

# Ensure Novarin directory exists
mkdir -p "$NOVARIN_DIR"

# Check if game files need to be restored
if [ ! -f "$NOVARIN_DIR/NovaLauncher.exe" ]; then
    echo "Restoring Novarin files..."
    cp -r /app/share/launcher/* "$NOVARIN_DIR/" 2>/dev/null || echo "Install is effed m8"
fi

# shellcheck disable=SC2068
wine "$NOVARIN_DIR/NovaLauncher.exe" -d --hide-wine-message $@