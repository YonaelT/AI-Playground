#!/bin/bash
# ==============================================================================
# Transparent FlipClock Launcher
# ==============================================================================
# This script launches 'flipclock' in fullscreen and applies window transparency.
# It uses robust window detection by PID to ensure transparency is applied
# even if the window takes a moment to appear.
# ==============================================================================

# Prevent running as root (sudo) as it breaks X11 display connection
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this script as root/sudo. It must run as the desktop user." >&2
    exit 1
fi

# Configuration
FLIPCLOCK_BIN="flipclock"
TRANSPARENCY_LEVEL="0.8" # Range: 0.0 (fully transparent) to 1.0 (fully opaque)
MAX_WAIT_SECONDS=10      # Max time to wait for the window to appear

# Check dependencies
for cmd in "$FLIPCLOCK_BIN" xdotool xprop awk; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required dependency '$cmd' is not installed." >&2
        if [ "$cmd" = "flipclock" ]; then
            echo "Please build and install flipclock from source first." >&2
        else
            echo "Please install it: sudo apt install xdotool x11-utils awk" >&2
        fi
        exit 1
    fi
done

# Calculate the transparency value for xprop (0x0 to 0xFFFFFFFF)
# Using awk to handle the float calculation reliably
TRANSPARENCY_HEX=$(printf "0x%x" $(awk "BEGIN {printf \"%d\", 0xFFFFFFFF * $TRANSPARENCY_LEVEL}"))

echo "Launching FlipClock in fullscreen..."
# Launch flipclock in fullscreen
"$FLIPCLOCK_BIN" -f &
FLIPCLOCK_PID=$!

echo "Waiting for FlipClock window (PID: $FLIPCLOCK_PID) to appear..."
WINDOW_ID=""
START_TIME=$(date +%s)

# Robust polling loop to find the exact window by PID
while true; do
    # Search for windows belonging to our specific PID
    # xdotool might return multiple IDs or error if not found yet, so we catch stderr
    WINDOW_ID=$(xdotool search --pid "$FLIPCLOCK_PID" 2>/dev/null | head -n 1)
    
    if [ -n "$WINDOW_ID" ]; then
        echo "Found FlipClock Window ID: $WINDOW_ID"
        break
    fi
    
    # Check if the process died prematurely
    if ! kill -0 "$FLIPCLOCK_PID" 2>/dev/null; then
        echo "ERROR: FlipClock process (PID: $FLIPCLOCK_PID) exited unexpectedly." >&2
        exit 1
    fi
    
    # Check timeout
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    if [ "$ELAPSED" -ge "$MAX_WAIT_SECONDS" ]; then
        echo "ERROR: Timeout waiting for FlipClock window to appear." >&2
        kill "$FLIPCLOCK_PID" 2>/dev/null
        exit 1
    fi
    
    sleep 0.1
done

# Apply transparency to the detected window
echo "Applying transparency level $TRANSPARENCY_LEVEL..."
if xprop -id "$WINDOW_ID" -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY "$TRANSPARENCY_HEX" 2>/dev/null; then
    echo "Transparency successfully applied."
else
    echo "ERROR: Failed to apply transparency using xprop." >&2
fi

# Wait for the flipclock process to exit (e.g. when user presses Esc or q)
wait "$FLIPCLOCK_PID"
echo "FlipClock exited."
