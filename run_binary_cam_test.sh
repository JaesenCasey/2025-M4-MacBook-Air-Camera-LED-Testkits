#!/bin/bash

LOG="results_binary.log"
RESOLUTION_MS=1     # stop narrowing once gap is this small
MAX_ITER=25          # hard cap so it can never loop forever

echo "=== binary search run $(date) ===" >> "$LOG"

ask_trial() {
    local ms=$1
    local fname="out_${ms}ms_$(date +%s%N).jpg"
    echo -n "duration=${ms}ms " >> "$LOG"
    ./testcam "$fname" "$ms" >> "$LOG" 2>&1
    echo "" >> "$LOG"
    read -p "Duration ${ms}ms — did you see the LED? (y/n): " saw
    echo "led_seen=${saw}" >> "$LOG"
    if [[ "$saw" == "y" ]]; then
        return 0   # hit
    else
        return 1   # miss
    fi
}

# Phase 1: exponential descent to find a bracket
hi=500   # ms, a value you already know is a "hit"
lo=""
current=$hi

while true; do
    ask_trial "$current"
    result=$?
    if [[ $result -eq 1 ]]; then
        lo=$current
        break
    else
        hi=$current
        current=$(echo "$current / 2" | bc)
        if [[ $current -lt 1 ]]; then
            echo "reached sub-1ms with no miss — floor may be below script resolution" >> "$LOG"
            echo "No miss found even at ${current}ms. Stopping."
            exit 0
        fi
    fi
done

echo "bracket found: hit=${hi}ms miss=${lo}ms" | tee -a "$LOG"

# Phase 2: binary search between hi (last seen) and lo (last missed)
iter=0
while [[ $((hi - lo)) -gt $RESOLUTION_MS && $iter -lt $MAX_ITER ]]; do
    mid=$(( (hi + lo) / 2 ))
    ask_trial "$mid"
    result=$?
    if [[ $result -eq 0 ]]; then
        hi=$mid
    else
        lo=$mid
    fi
    iter=$((iter+1))
done

echo "=== converged: hit_floor=${hi}ms miss_ceiling=${lo}ms after ${iter} iterations ===" | tee -a "$LOG"