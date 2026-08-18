#!/bin/bash
for ms in 500 200 100 50 30 20 15 10 5 2; do
  for trial in 1 2 3 4 5; do
    fname="out_${ms}ms_t${trial}.jpg"
    echo -n "duration=${ms}ms trial=${trial} " >> results.log
    ./testcam "$fname" "$ms" >> results.log 2>&1
    echo "" >> results.log
    read -p "Did you see the LED? (y/n): " saw
    echo "led_seen=${saw}" >> results.log
    sleep 1
  done
done