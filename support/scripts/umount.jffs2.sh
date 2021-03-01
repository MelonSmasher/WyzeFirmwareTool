#!/bin/bash
set -e

DST=${1}
SYNC=${2}

if [[ -z "${1:-}" ]]; then
  echo "Usage: umount.jffs2 DST SYNC_FILE"
  exit
fi

if [[ ${EUID} -ne 0 ]]; then
  echo "mount.jffs2: only root can do that" 1>&2
  exit 1
fi

sudo mkfs.jffs2 -l -n -X lzo -x zlib -x rtime -d ${DST} -o ${SYNC}

if sudo umount ${DST}; then
  rmmod mtdblock 2>/dev/null
  rmmod mtdram 2>/dev/null
  rmmod jffs2 2>/dev/null
fi