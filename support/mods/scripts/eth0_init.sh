#!/bin/sh

sleep 8
if [ $(lsusb | wc -l) -ge 2 ]; then
  ifconfig eth0 up && udhcpc -i eth0 -p /var/run/udhcpc_eth0.pid -b
fi
