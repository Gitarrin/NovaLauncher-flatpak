#!/bin/bash
export WINEPREFIX=/var/data/wine-prefix
export PATH="/app/bin:/app/lib/wine/bin:$PATH"

show_first_setup_dialog() {
    zenity --progress --pulsate --no-cancel \
        --title="Novarin" \
        --text="Preparing for first launch, this may take several minutes...\nThe OK button does not do anything, this dialog will close automatically once configuration is done." &
    DIALOG_PID=$!
    # Window positioning maybe, dont think it works on wayland
    # wmctrl -i -r $(xdotool getactivewindow) -b add,above || true
}

close_setup_dialog() {
    if [ -n "$DIALOG_PID" ]; then
        kill $DIALOG_PID 2>/dev/null || true
    fi
}

FIRST_RUN=false
if [ ! -d "$WINEPREFIX" ] || [ ! -f "$WINEPREFIX/.dxvk_installed" ]; then
    FIRST_RUN=true
fi

if [ "$FIRST_RUN" = true ]; then
    show_first_setup_dialog
fi

# Create Wine prefix if it doesn't exist
if [ ! -d "$WINEPREFIX" ]; then
    echo "Initializing Wine prefix..."
    wineboot -i
    # Additional Wine configuration can go here
fi

# Setup DXVK if not already installed
if [ ! -f "$WINEPREFIX/.dxvk_installed" ]; then
    echo "Installing DXVK..."
    winetricks corefonts # this also helps the DVXK install properly
    # Wait for wineboot to complete
    /app/lib/dvxk/setup-dvxk.sh /app/lib/dvxk/ install
    
    # Setup the pics folder
    mkdir -p "$HOME/Pictures/Novarin Screenshots"

    # Create Wine prefix directories if they don't exist
    WINE_USERNAME=$(whoami)
    WINE_PICTURES_DIR="/var/data/wine-prefix/drive_c/users/$WINE_USERNAME/Pictures"
    mkdir -p "$WINE_PICTURES_DIR"

    # Remove existing Roblox directory if it exists and create symbolic link
    rm -rf "$WINE_PICTURES_DIR/Roblox"
    ln -sf "$HOME/Pictures/Novarin Screenshots" "$WINE_PICTURES_DIR/Roblox"

    # I apoligze to people who have to see this cursed thing
    # mv "$WINEPREFIX/drive_c/windows/explorer.exe" "$WINEPREFIX/drive_c/windows/explorer_real.exe"
    # cp "/app/bin/dummy-explorer.sh" "$WINEPREFIX/drive_c/windows/explorer.exe"

    
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
    cp -r /app/share/launcher/* "$NOVARIN_DIR/" 2>/dev/null || echo "the installler has run away"
fi

if [ "$FIRST_RUN" = true ]; then
    close_setup_dialog
fi

# shellcheck disable=SC2068
wine "$NOVARIN_DIR/NovaLauncher.exe" -d --hide-wine-message $@
wineserver -w