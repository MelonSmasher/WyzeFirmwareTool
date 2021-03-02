#!/bin/sh

# Take a hammer to wpa_supplicant
killall -9 wpa_supplicant
sleep 5
killall -9 wpa_supplicant

# Take down wlan0
ifconfig wlan0 down

# Kill off udhcpc -t 10 -i wlan0 -p /var/run/udhcpc.pid -b
while :
do
  udhcpc_pid=$(ps | grep udhcpc | grep wlan0 | awk '{$1=$1};1' | cut -d ' ' -f 1)
  if [ -z "${udhcpc_pid}" ];
    exit 0
  else
    kill -9 $udhcpc_pid
  fi
  sleep 1
done