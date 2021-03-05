#!/bin/sh

# Borrowed from HclX/WyzeHacks

mount_nfs() {
    NFS_ROOT=$1
    NFS_OPTIONS=$2
    DEVICE_ID=$(grep -oE "NETRELATED_MAC=[A-F0-9]{12}" /params/config/.product_config | sed 's/NETRELATED_MAC=//g')

    local NFS_MOUNT="/bin/mount $NFS_OPTIONS"
    local RETRY_COUNT=0
    while true
    do
        # We will try mount the NFS for 10 times, and fail if still not available
        let RETRY_COUNT=$RETRY_COUNT+1
        if [ $RETRY_COUNT -gt 100 ]; then
            return 1
        fi

        if ! /bin/mount | grep -q "$NFS_ROOT on /mnt";
        then
            echo "WyzeHack: $NFS_ROOT not mounted, try mounting to /mnt..."
            if ! $NFS_MOUNT $NFS_ROOT /mnt;
            then
                echo "WyzeHack: [$NFS_MOUNT $NFS_ROOT /mnt] failed, will retry..."
                sleep 10
                continue
            fi
        fi

        local CAM_DIR=/mnt/WyzeCams/$DEVICE_ID
        for DIR in /mnt/WyzeCams/*/;
        do
            if [ -f "$DIR/.mac_$DEVICE_ID" ];
            then
                CAM_DIR="$DIR"
                break
            fi
        done

        echo "WyzeHack: Mounting directory $CAM_DIR as SD card"
        if [ ! -d "$CAM_DIR" ];
        then
            echo "WyzeHack: Creating data directory [$CAM_DIR]"
            if ! mkdir -p "$CAM_DIR";
            then
                echo "WyzeHack: [mkdir -p $CAM_DIR] failed, will retry..."
                sleep 1
                continue
            fi
        fi

        echo "WyzeHack: Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmcblk0p1"
        mkdir -p /media/mmcblk0p1
        if ! mount -o bind "$CAM_DIR" /media/mmcblk0p1;
        then
            echo "WyzeHack: mount $CAM_DIR as /media/mmcblk0p1 failed, will retry..."
            sleep 5
            continue
        fi

        echo "WyzeHack: Mounting camera directory $NFS_ROOT/$CAM_DIR on /media/mmc"
        mkdir -p /media/mmc
        if ! mount -o bind "$CAM_DIR" /media/mmc;
        then
            echo "WyzeHack: mount $CAM_DIR as /media/mmc failed, will retry..."
            sleep 5
            continue
        fi

        break
    done

    echo "WyzeHack: Notifying iCamera about SD card insertion event..."
    /bin/hackutils mmc_insert

    # Mark this directory for this camera
    touch /media/mmcblk0p1/.mac_$DEVICE_ID

    return 0
}

MY_NFS_HOST=
MY_NFS_ROOT=
MY_NFS_OPTS=

printf "%s" "waiting for NFS Server ..."
while ! ping -c 1 -n -w 1 $MY_NFS_HOST &> /dev/null
do
    printf "%c" "."
done

mount_nfs "${MY_NFS_ROOT}" "${MY_NFS_OPTS}"
