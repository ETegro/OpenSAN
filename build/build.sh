#!/bin/bash -ex

WORK_DIR=`echo $0 | sed "s/build.sh$//"`
TARGET_DIR="$WORK_DIR"/openwrt/trunk

. "$WORK_DIR"/build.conf

checkout_openwrt()
{
	$SVN -r$OPENWRT_TRUNK_REVISION checkout $OPENWRT_TRUNK_URL "$TARGET_DIR"
}

check_openwrt_existence()
{
	[ -d "$TARGET_DIR" ] || mkdir -p "$TARGET_DIR"
	[ -d "$TARGET_DIR"/.svn ] || checkout_openwrt
	pushd "$TARGET_DIR"
	$SVN update -r$OPENWRT_TRUNK_REVISION || checkout_openwrt
	popd
}

check_openwrt_existence
