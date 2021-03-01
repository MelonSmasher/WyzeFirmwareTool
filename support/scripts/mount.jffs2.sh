#!/bin/sh
#
# script to mount a jffs2-image a loopback device
# ©Thomas Fischer 2008
# This script may be distributed, altered, reverse-engineered,
# rebranded or thrown across the room at leisure, as long as
# nobody blames me for it.
#
# Chapter one: Sanity Test
#   Find out if what we're doing is actually making any sense
#   Note: this section could use a good expanding. Meanwhile,
#   it's the ole 'Think before you type'
#
# Oh, and of course we need to react to the cry for help:
case "$1" in

--help|-h)
	 echo Usage: mntjffs \<jffs2-image\> \<mountpoint\>
	 echo
	 echo Script will exit with a return code of 0 in case of success,
	 echo return code of 1 indicates UID not 0, return code of 2
	 echo indicates sanity check failed, return code of 3 finally indicates
	 echo something went wrong during the mount procedure
	 ;;

# Except for that, we let things take their natural course...
*)

SANITY_CHECK=0
if [ $(file -b $1 |cut -d ' ' -f2) = "jffs2" ] && [ -d $2 ]; then

  SANITY_CHECK=1
  echo Sanity check passed...

fi


# Chapter Two: Mounting
#   probe all the mods, set up the loops, mount the mtds.
#   check first if we are root, if we are not, the probing
#   might be a wee difficult
#
#   FYI: The sleeps are necessary because for some reason
#   the /dev/mtdblock devices take a second or two to show up.
if [ `id -u` -ne 0 ]; then
  echo "This script needs to be run as root"
  exit 1
fi

if [ $SANITY_CHECK -eq 1 ]; then
	export loop=$(losetup -f) && \
	losetup $loop $1 && \
	modprobe block2mtd block2mtd=$loop,131072 && \
	sleep 2 && \
	modprobe jffs2 && \
	sleep 2 && \
	modprobe mtdblock && \
	sleep 2 && \
	mount -t jffs2 -o rw /dev/mtdblock0 $2 && \
	( echo -n "Image ";echo -n $1;echo -n " sucessfully mounted on ";echo $2 ) && \
	exit 0 || echo mount failed, check dmesg \|tail for pointers;exit 3
else
	echo SANITY CHECK FAILED!
	echo
	echo Something\'s not right here, chummer.
	echo Make sure you have a valid jffs2 image AND a valid directory to mount it on.
	echo And remember: Think before you type, or bad things may happen -- all sanity
	echo checking of this world will not save your butt if you act foolishly
	echo
	echo  Usage: mntjffs \<jffs2-image\> \<mountpoint\>
	exit 2
fi
;;

esac