#!/bin/sh

sleep 1

USB_COUNT=$(lsusb | wc -l)

if [ $USB_COUNT -ge 2 ]; then
  ifconfig eth0 up
  sleep 9
  udhcpc -i eth0 -p /var/run/udhcpc_eth0.pid -b
fi
