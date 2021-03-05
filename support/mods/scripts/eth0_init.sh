#!/bin/sh

sleep 5

USB_COUNT=$(lsusb | wc -l)

if [ $USB_COUNT -ge 2 ]; then
  ifconfig eth0 up
  udhcpc -i eth0 -p /var/run/udhcpc_eth0.pid -b
fi
