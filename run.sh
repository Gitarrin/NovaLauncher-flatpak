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
    /app/lib/soda/bin/wineboot -i
    # Additional Wine configuration can go here
fi

# Setup DXVK if not already installed
if [ ! -f "$WINEPREFIX/.dxvk_installed" ]; then
    echo "Installing DXVK..."

    # this also helps the DVXK install properly. Why is it not in here? because it would break winetricks for some reason.
    WINE=/app/lib/soda/bin/wine winetricks -q wininet winhttp mfc80 mfc90 gdiplus wsh56 urlmon pptfonts corefonts pdh \
        qasf wmp11 # The video recorder feature

    /app/lib/dvxk/setup-dvxk.sh /app/lib/dvxk/ install
    
    # Setup the pics folder
    mkdir -p "$HOME/Pictures/Novarin Screenshots"

    # Create Wine prefix directories if they don't exist
    #WINE_USERNAME=$(whoami)
    WINE_USERS_DIR="/var/data/wine-prefix/drive_c/users/steamuser/"

    # Configure Pictures folder
    mkdir -p "$WINE_USERS_DIR/Pictures"

    # Remove existing Roblox directory if it exists and create symbolic link
    rm -rf "$WINE_USERS_DIR/Pictures/Roblox"
    ln -sf "$HOME/Pictures/Novarin Screenshots" "$WINE_USERS_DIR/Pictures/Roblox"

    # Configure Pictures folder
    mkdir -p "$WINE_USERS_DIR/Videos"

    # Remove existing Roblox directory if it exists and create symbolic link
    rm -rf "$WINE_USERS_DIR/Videos/Roblox"
    ln -sf "$HOME/Videos/Novarin Recordings" "$WINE_USERS_DIR/Videos/Roblox"
    

    # Registry tweaks to avoid the wine filemanager
    /app/lib/soda/bin/wine reg import /app/share/regfiles/remap-filemanager.reg

    # And commit war crimes to use our script instead of the wine browser
    # mv "$WINEPREFIX/drive_c/windows/system32/winebrowser.exe" "$WINEPREFIX/drive_c/windows/system32/winebrowser_real.exe"
    # cp "/app/bin/dummy-filemanager.sh" "$WINEPREFIX/drive_c/windows/system32/winebrowser.exe"
    
    # Mark DXVK as installed
    touch "$WINEPREFIX/.dxvk_installed"
    echo "DXVK installation complete"
   
fi

# WINE_USER=$(find "$WINEPREFIX/drive_c/users/" -maxdepth 1 -type d | grep -v "Public\|users" | xargs basename 2>/dev/null || whoami)
NOVARIN_DIR="$WINEPREFIX/drive_c/users/steamuser/AppData/Local/Novarin"

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
WINEDLLOVERRIDES="wininet=b,n;winhttp=n,b" /app/lib/soda/bin/wine "$NOVARIN_DIR/NovaLauncher.exe" --hide-wine-message $@
/app/lib/soda/bin/wineserver -w