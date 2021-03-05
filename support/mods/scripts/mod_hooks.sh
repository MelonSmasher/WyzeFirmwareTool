#!/bin/sh

load_eth0_kos() {
  insmod /driver/usbnet.ko
  insmod /driver/asix.ko
}

look_for_icamera() {
  look_for_icamera=true
  while $look_for_icamera; do
    pid=$(ps | grep iCamera | grep -v "grep" | awk '{$1=$1};1' | cut -d ' ' -f 1)
    if [ -z "${pid}" ]; then
      sleep 1
    else
      look_for_icamera=false
    fi
  done
}

# load_eth0_kos
look_for_icamera
# /root/mods/eth0_init.sh &
# /root/mods/wlan0_kill.sh &
