#!/bin/sh

mount_nfs() {
  SD_ROOT='/media/mmc'
  NFS_MOUNT_DIR='/media/nfs'
  NFS_ROOT=$1
  NFS_OPTIONS=$2
  DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')

  local NFS_MOUNT="/bin/mount $NFS_OPTIONS"
  local RETRY_COUNT=0

  while true; do
    let RETRY_COUNT=$RETRY_COUNT+1
    if [ $RETRY_COUNT -gt 100 ]; then
      return 1
    fi

    if ! /bin/mount | grep -q "$NFS_ROOT on $NFS_MOUNT_DIR"; then
      # Make our mount dir
      mkdir -p $NFS_MOUNT_DIR
      # Mount the NFS volume
      if ! $NFS_MOUNT $NFS_ROOT $NFS_MOUNT_DIR; then
        sleep 10
        continue
      fi
    fi

    # Determine the NFS share directory for this camera based on the device ID/MAC
    local CAM_DIR=$NFS_MOUNT_DIR/WyzeCams/$DEVICE_ID
    for DIR in $NFS_MOUNT_DIR/WyzeCams/*/; do
      if [ -f "$DIR/.mac_$DEVICE_ID" ]; then
        CAM_DIR="$DIR"
        break
      fi
    done

    # Make the camera's directory if it does not exists
    if [ ! -d "$CAM_DIR" ]; then
      echo "WyzeHack: Creating data directory [$CAM_DIR]"
      if ! mkdir -p "$CAM_DIR"; then
        echo "WyzeHack: [mkdir -p $CAM_DIR] failed, will retry..."
        sleep 1
        continue
      fi
    fi

    # Bind mount over the SD card
    if ! mount -o bind "${CAM_DIR}" "${SD_ROOT}"; then
      echo "Bind $CAM_DIR as ${SD_ROOT} failed, will retry..."
      sleep 5
      continue
    fi

    break
  done

  return 0
}

MY_NFS_HOST=
MY_NFS_ROOT=
MY_NFS_OPTS=

# Wait for the camera to have network to reach the NFS server
printf "%s" "waiting for NFS Server ..."
while ! ping -c 1 -n $MY_NFS_HOST &>/dev/null; do
  printf "%c" "."
done

# Run the mount function
mount_nfs "${MY_NFS_ROOT}" "${MY_NFS_OPTS}"
