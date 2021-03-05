#!/bin/sh

# Poor dude's service to ensure that eth0 always ends up with an IP

auto_eth0() {
  # If we have more than one USB device
  if [ $(lsusb | wc -l) -ge 2 ]; then
    # Set eth0 down
    ifconfig eth0 down || true
    # Bring eth0 up
    ifconfig eth0 up
    # Remove any IP on eth0
    ifconfig eth0 0.0.0.0
    # Grab the PID of any DHCP process running for eth0
    udhcpc_pid=$(ps | grep udhcpc | grep -v "grep" | grep eth0 | awk '{$1=$1};1' | cut -d ' ' -f 1)
    # Is the PID empty?
    if [ -z "${udhcpc_pid}" ]; then
      # If the PID is empty nothing to do
      echo 'No DHCP process running for eth0'
    else
      # If there is a PID kill it
      kill -9 $udhcpc_pid
    fi
    # Request a new DHCP lease for eth0
    udhcpc -t 10 -i eth0 -p /var/run/udhcpc_eth0.pid -b
    GATEWAY_IP=$(route -n | grep "UG" | awk -F' ' '{print $2}')
    ping $GATEWAY_IP 2>&1 >/dev/null &
  fi
}

GATEWAY_IP_FAILS=0

# Infinite loop to ensure that eth0 ends up with an IP
while :; do
  # Get the IP for eth0
  eth0_ip=$(ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}')
  # Check if there is an IP
  if [ -z "${eth0_ip}" ]; then
    # If there is not an IP lets set up eth0
    auto_eth0
  else
    # Get the gateway IP
    GATEWAY_IP=$(route -n | grep "UG" | awk -F' ' '{print $2}')
    # Try to ping the IP
    if ! ping -c 1 -n $GATEWAY_IP &>/dev/null; then
      # If it fails keep track of it
      GATEWAY_IP_FAILS=$GATEWAY_IP_FAILS+1
    else
      # If it does not fail set to 0s
      GATEWAY_IP_FAILS=0
    fi
    # Have we failed more than once in the last minute?
    if [ $GATEWAY_IP_FAILS -gt 1 ]; then
      # Reboot
      sync
      sleep 10
      /sbin/reboot
    fi
    # Sleep for 25
    sleep 25
  fi
  # Check again in 5 seconds
  sleep 5
done
