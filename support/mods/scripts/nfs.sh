#!/bin/sh

mount_nfs() {
  SD_ROOT='/media/mmc'
  NFS_MOUNT_DIR='/media/nfs'
  NFS_ROOT=$1
  NFS_OPTIONS=$2
  DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')

  NFS_MOUNT="/bin/mount $NFS_OPTIONS"

  # Make our mount dir
  mkdir -p $NFS_MOUNT_DIR
  # Mount the NFS volume
  $NFS_MOUNT $NFS_ROOT $NFS_MOUNT_DIR

  # Determine the NFS share directory for this camera based on the device ID/MAC
  CAM_DIR=$NFS_MOUNT_DIR/WyzeCams/$DEVICE_ID
  NFS_ROOT_REC="${NFS_ROOT}/WyzeCams/${DEVICE_ID}/record"
  NFS_ROOT_TL="${NFS_ROOT}/WyzeCams/${DEVICE_ID}/time_lapse"
  for DIR in $NFS_MOUNT_DIR/WyzeCams/*/; do
    if [ -f "$DIR/.mac_$DEVICE_ID" ]; then
      CAM_DIR="$DIR"
      NFS_ROOT_REC="${NFS_ROOT}/WyzeCams/${$DIR##*/}/record"
      NFS_ROOT_TL="${NFS_ROOT}/WyzeCams/${$DIR##*/}/time_lapse"
      break
    fi
  done

  # Make sure all of the required dirs exist
  mkdir -p "${CAM_DIR}"
  mkdir -p "${CAM_DIR}/record"
  mkdir -p "${CAM_DIR}/time_lapse"
  mkdir -p "${SD_ROOT}/record"
  mkdir -p "${SD_ROOT}/time_lapse"

  # Mount the record and time_lapse dir directly at the SD Card
  $NFS_MOUNT $NFS_ROOT_REC "${SD_ROOT}/record"
  $NFS_MOUNT $NFS_ROOT_TL "${SD_ROOT}/time_lapse"

  # Mark this directory for this camera
  touch "${CAM_DIR}/.mac_${DEVICE_ID}"

  return 0
}

MY_NFS_HOST=
MY_NFS_ROOT=
MY_NFS_OPTS=
NFS_HOST_PING_FAILS=0

# Wait for the camera to have network to reach the NFS server
printf "%s" "waiting for NFS Server ..."
while ! ping -c 1 -n $MY_NFS_HOST &>/dev/null; do
  printf "%c" "."
done

# Wait for everything to fire up
#sleep 5

# Run the mount function
mount_nfs "${MY_NFS_ROOT}" "${MY_NFS_OPTS}"

# Check that the NFS server is reachable. If the connection drops for 1 minute reboot the camera
while :; do
  if ! ping -c 1 -n $MY_NFS_HOST &>/dev/null; then
    NFS_HOST_PING_FAILS=$NFS_HOST_PING_FAILS+1
  else
    NFS_HOST_PING_FAILS=0
  fi
  if [ $NFS_HOST_PING_FAILS -gt 1 ]; then
    sync
    sleep 10
    /sbin/reboot
  fi
  sleep 30
done
