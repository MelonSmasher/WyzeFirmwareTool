#!/bin/sh

insmod /driver/usbnet.ko
insmod /driver/asix.ko
ifconfig eth0 up
udhcpc -i eth0 -p /var/run/udhcpc_eth0.pid -b
