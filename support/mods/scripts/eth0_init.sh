#!/bin/sh

sleep 5
if [ $(lsusb | wc -l) -ge 2 ]; then
  sleep 1
  ifconfig eth0 up
  sleep 1
  udhcpc -i eth0 -p /var/run/udhcpc_eth0.pid -b
fi
