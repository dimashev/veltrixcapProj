#!/bin/bash
timestamp=$(date +%s)
outputWtimestamp= "output"+ $timestamp

PID=ps -ef | awk '$8=="app" {print $2}'

if PID != ""
  break
  
echo "[Swap Optimizer] Starting the path-finder service..." >> logs/${outputWtimestamp}.log

# Ensure .env exists
if [ ! -f .env ]; then
    echo "[ERROR] Missing .env file. Please run setup.sh first." >> logs/${outputWtimestamp}.log
    exit 1
fi

# Run orchestrator logic
echo "[Swap Optimizer] Starting orchestrator..." >> logs/${outputWtimestamp}.log
npm run build & npm start &

(
  sleep 300
  pkill -f "node src/app.js"

  echo "[SWAP OPTIMIZER] Simulated crash: app.js stopped after 5 minutes." >> logs/${outputWtimestamp}.log
) &

wait
