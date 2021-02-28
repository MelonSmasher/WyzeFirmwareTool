#!/bin/bash
set -e

SRC=${1}
DST=${2}

if [[ -z "${2:-}" ]]; then
  echo "Usage: mount.jffs2 SRC DST"
  exit
fi

if mount | grep -q mtdblock0; then
  echo "${SRC} already mounted" 1>&2
  exit 1
fi

if [[ ${EUID} -ne 0 ]]; then
  echo "mount.jffs2: only root can do that" 1>&2
  exit 1
fi

rmmod mtdblock 2>/dev/null || true
rmmod mtdram 2>/dev/null || true
rmmod jffs2 2>/dev/null || true

modprobe mtdblock
modprobe mtdram total_size=65536 erase_size=256
modprobe jffs2

dd if="${SRC}" of=/dev/mtdblock0 2>/dev/null
mount -t jffs2 /dev/mtdblock0 "${DST}"