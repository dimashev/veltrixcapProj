#!/bin/bash

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="logs/run_${TIMESTAMP}.log"
PIDFILE="logs/app.pid"

mkdir -p logs

# Check for PID lock
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo "[ERROR] Application already running with PID $OLD_PID" | tee -a "$LOGFILE"
        exit 1
    else
        echo "[WARN] Stale PID file found. Removing..." | tee -a "$LOGFILE"
        rm -f "$PIDFILE"
    fi
fi

echo "[Swap Optimizer] Starting the path-finder service..." | tee -a "$LOGFILE"

# Ensure .env exists
if [ ! -f .env ]; then
    echo "[ERROR] Missing .env file. Please run setup.sh first." >> "$LOGFILE"
    exit 1
fi

# Run orchestrator logic
echo "[Swap Optimizer] Starting orchestrator..." >> "$LOGFILE"
npm run build >> "$LOGFILE" 2>&1 && npm start >> "$LOGFILE" 2>&1 &
APP_PID=$!

# Store PID
echo $APP_PID > "$PIDFILE"

(
  sleep 300
  pkill -f "node dist/app.js"
  echo "[SWAP OPTIMIZER] Simulated crash: app.js stopped after 5 minutes." >> "$LOGFILE"
) &

# Wait for app and check exit code
wait $APP_PID
EXIT_CODE=$?

# Clean up PID file
rm -f "$PIDFILE"

# Exit with app's exit code
if [ $EXIT_CODE -ne 0 ]; then
    echo "[ERROR] Application terminated abnormally with exit code $EXIT_CODE" >> "$LOGFILE"
    exit $EXIT_CODE
fi

echo "[Swap Optimizer] Application terminated normally" >> "$LOGFILE"
exit 0
