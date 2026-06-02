#!/bin/bash
# ==============================================================================
# Transparent FlipClock Screensaver Daemon
# ==============================================================================
# This script monitors user idle time using 'xprintidle'. When the user is idle
# for the configured threshold, it launches the transparent flipclock.
# When activity is detected, it terminates the clock.
# ==============================================================================

# Prevent running as root (sudo)
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this script as root/sudo. It must run as the desktop user." >&2
    exit 1
fi

# Configuration
IDLE_THRESHOLD_SECONDS=60 # 1 minute (60 seconds)
CHECK_INTERVAL_SECONDS=2   # Check idle state every 2 seconds
LAUNCHER_SCRIPT="/home/yonael/AI-Playground/launch_transparent_flipclock.sh"

# Check dependencies
for cmd in xprintidle "$LAUNCHER_SCRIPT"; do
    if [ "$cmd" = "$LAUNCHER_SCRIPT" ]; then
        if [ ! -f "$LAUNCHER_SCRIPT" ]; then
            echo "ERROR: Launcher script not found at '$LAUNCHER_SCRIPT'" >&2
            exit 1
        fi
    elif ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required dependency '$cmd' is not installed." >&2
        echo "Please install it: sudo apt install xprintidle" >&2
        exit 1
    fi
done

IDLE_THRESHOLD_MS=$((IDLE_THRESHOLD_SECONDS * 1000))
FLIPCLOCK_LAUNCH_PID=""

function stop_flipclock() {
    if [ -n "$FLIPCLOCK_LAUNCH_PID" ]; then
        echo "$(date): Activity detected. Terminating FlipClock..."
        
        # Kill the launcher script and its children (the actual flipclock binary)
        # We kill the process group or use pkill to make sure the binary is terminated
        kill "$FLIPCLOCK_LAUNCH_PID" 2>/dev/null
        pkill -f "flipclock" 2>/dev/null
        
        # Wait for the background process to be fully cleaned up
        wait "$FLIPCLOCK_LAUNCH_PID" 2>/dev/null
        FLIPCLOCK_LAUNCH_PID=""
    fi
}

function start_flipclock() {
    if [ -z "$FLIPCLOCK_LAUNCH_PID" ]; then
        echo "$(date): Idle threshold reached ($IDLE_THRESHOLD_SECONDSs). Launching FlipClock..."
        
        # Launch the launcher script in the background
        # Redirect stdout and stderr to a log file for easy debugging
        /bin/bash "$LAUNCHER_SCRIPT" > /home/yonael/AI-Playground/screensaver.log 2>&1 &
        FLIPCLOCK_LAUNCH_PID=$!
        
        # Give it a second to see if it immediately fails
        sleep 1
        if ! kill -0 "$FLIPCLOCK_LAUNCH_PID" 2>/dev/null; then
            echo "WARNING: Launcher exited immediately. Check /home/yonael/AI-Playground/screensaver.log" >&2
            FLIPCLOCK_LAUNCH_PID=""
        fi
    fi
}

# Ensure everything is cleaned up if this script is terminated
trap stop_flipclock EXIT SIGINT SIGTERM

echo "Starting FlipClock screensaver daemon..."
echo "Idle threshold: $IDLE_THRESHOLD_SECONDS seconds ($((IDLE_THRESHOLD_SECONDS / 60)) minutes)"
echo "Check interval: $CHECK_INTERVAL_SECONDS seconds"

while true; do
    # Get idle time in milliseconds
    IDLE_MS=$(xprintidle 2>/dev/null)
    
    if [ -z "$IDLE_MS" ]; then
        echo "ERROR: Failed to retrieve idle time from xprintidle." >&2
        sleep "$CHECK_INTERVAL_SECONDS"
        continue
    fi
    
    if [ "$IDLE_MS" -ge "$IDLE_THRESHOLD_MS" ]; then
        start_flipclock
    else
        stop_flipclock
    fi
    
    sleep "$CHECK_INTERVAL_SECONDS"
done
