#!/bin/sh

################################################################################
# Swupdate script called automatically with either
# "preinst" or "postinst" as arguments by update process
# Assumes following disk/flash layout:
# /dev/mmcblk0p1 boot partition (vfat) u-boot, kernel, devicetree, uEnv.txt
# /dev/mmcblk0p2 rootfs1 (ext) active or standby
# /dev/mmcblk0p3 rootfs2 (ext) active or standby
# /dev/mmcblk0p4 persistent data (application and user config)
#
# standby partition will be updated by this script
#
#
# !! Do not run if you don't understand what it does!!
################################################################################

set -e

# provides functions like get_standby_root etc.
test -e /etc/swupdate/swupdate.in && . /etc/swupdate/swupdate.in

# Make sure uEnv exists and contains ACTIVE_ROOT and STANDBY_ROOT variables
function check_uenv(){
    if [ ! -e /boot/uEnv.txt ]
    then
	echo "cannot update /boot/uEnv.txt - no such file or directory"
	exit -2
    fi

    grep -q "ACTIVE_ROOT=/dev/mmcblk0" /boot/uEnv.txt
    if [ $? -ne 0 ]
    then
	echo "malformatted uEnv.txt - ACTIVE_ROOT not found"
	exit -2
    fi

    grep -q "STANDBY_ROOT=/dev/mmcblk0" /boot/uEnv.txt
    if [ $? -ne 0 ]
    then
	echo "malformatted uEnv.txt - STANDBY_ROOT not found"
	exit -2
    fi
}


function update_uenv(){
    # Swap ACTIVE_ROOT and STANDBY_ROOT
    get_standby_root
    sed -i "s%STANDBY_ROOT=\/dev\/mmcblk0p[[:digit:]]%STANDBY_ROOT=$ACTIVE_ROOT%" /boot/uEnv.txt
    sed -i "s%ACTIVE_ROOT=\/dev\/mmcblk0p[[:digit:]]%ACTIVE_ROOT=$STANDBY_ROOT%" /boot/uEnv.txt
}


function preinst_actions(){
    get_standby_root
    if [ -e $STANDBY_ROOT ] ;
    then
	printf "Updating %s" $STANDBY_ROOT
    else
	printf "standby root %s not found!" $STANDBY_ROOT
	exit 1
    fi
    check_uenv
}


function postinst_actions(){
    check_uenv
    update_uenv
    sync
    echo "rebooting"
    reboot
}


case "$1" in
    preinst)
	preinst_actions
    ;;
    postinst)
	postinst_actions
    ;;
    *)
	echo "Usage: $0 {preinst|postinst}"
	exit 1
esac
