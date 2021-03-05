#!/bin/sh

kill_wpa_supplicant() {
  look_for_wpa_supplicant=true
  while $look_for_wpa_supplicant
  do
    wpa_supplicant_pid=$(ps | grep wpa_supplicant | grep -v "grep" | grep wlan0 | awk '{$1=$1};1' | cut -d ' ' -f 1)
    if [ -z "${wpa_supplicant_pid}" ]; then
      look_for_wpa_supplicant=false
    else
      killall -9 wpa_supplicant
    fi
    sleep 5
  done
}

kill_udhcpc() {
  look_for_udhcpc=true
  while $look_for_udhcpc
  do
    udhcpc_pid=$(ps | grep udhcpc | grep -v "grep" | grep wlan0 | awk '{$1=$1};1' | cut -d ' ' -f 1)
    if [ -z "${udhcpc_pid}" ]; then
      look_for_udhcpc=false
    else
      kill -9 $udhcpc_pid
    fi
    sleep 5
  done
}

# Infinite loop to ensure that eth0 ends up with an IP
while :
do
  # Get the IP for eth0
  eth0_ip=$(ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
  # Check if there is an IP
  if [ -z "${eth0_ip}" ]; then
    # If there is not an IP lets wait
    sleep 1
  else
    # Take down wlan0
    ifconfig wlan0 down
    # Take a hammer to wpa_supplicant
    kill_wpa_supplicant &
    # Kill off udhcpc for wlan0
    kill_udhcpc &
    # Wait for background functions to complete
    wait
  fi
done
