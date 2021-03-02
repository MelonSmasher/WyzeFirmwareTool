#!/bin/sh

# Wait for everything to start
sleep 10
# Take down wlan0
ifconfig wlan0 down

# Take a hammer to wpa_supplicant
look_for_wpa_supplicant=true
while $look_for_wpa_supplicant
do
  wpa_supplicant_pid=$(ps | grep wpa_supplicant | grep wlan0 | awk '{$1=$1};1' | cut -d ' ' -f 1)
  if [ -z "${wpa_supplicant_pid}" ]; then
    look_for_wpa_supplicant=false
  else
    killall -9 wpa_supplicant
  fi
  sleep 1
done

# Kill off udhcpc -t 10 -i wlan0 -p /var/run/udhcpc.pid -b
while :
do
  udhcpc_pid=$(ps | grep udhcpc | grep wlan0 | awk '{$1=$1};1' | cut -d ' ' -f 1)
  if [ -z "${udhcpc_pid}" ]; then
    exit 0
  else
    kill -9 $udhcpc_pid
  fi
  sleep 1
done