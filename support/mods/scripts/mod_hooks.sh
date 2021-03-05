#!/bin/sh

look_for_icamera=true
while $look_for_icamera
do
  sleep 1
  pid=$(ps | grep iCamera | grep -v "grep" | awk '{$1=$1};1' | cut -d ' ' -f 1)
  if [ ! -z "${pid}" ]; then
    look_for_icamera=false
  fi
done

# /root/mods/eth0_init.sh &
# /root/mods/wlan0_kill.sh &