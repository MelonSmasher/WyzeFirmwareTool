#!/bin/sh

sleep 15

USB_COUNT=$(lsusb | wc -l)

if [ $USB_COUNT -ge 2 ]; then
  insmod /driver/usbnet.ko
  insmod /driver/asix.ko
  sleep 1
  ifconfig eth0 up
  sleep 1
  udhcpc -i eth0 -p /var/run/udhcpc_eth0.pid -b
fi
