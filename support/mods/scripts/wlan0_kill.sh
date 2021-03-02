#!/bin/sh

kill_wpa_supplicant() {
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
    sleep 30
  done
}

kill_udhcpc() {
  look_for_udhcpc=true
  while $look_for_udhcpc
  do
    udhcpc_pid=$(ps | grep udhcpc | grep wlan0 | awk '{$1=$1};1' | cut -d ' ' -f 1)
    if [ -z "${udhcpc_pid}" ]; then
      exit 0
    else
      kill -9 $udhcpc_pid
    fi
    sleep 30
  done
}

# Wait for everything to start
sleep 10
# Take down wlan0
ifconfig wlan0 down
# Take a hammer to wpa_supplicant
kill_wpa_supplicant &
# Kill off udhcpc for wlan0
kill_udhcpc &
# Wait for background functions to complete
wait