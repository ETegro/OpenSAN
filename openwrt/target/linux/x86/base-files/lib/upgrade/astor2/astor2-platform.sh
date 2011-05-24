#!/bin/dash -x

DD=dd
GUNZIP=gunzip
CPIO=gnu-cpio
FDISK=fdisk

IMAGE_VMLINUZ=vmlinuz
MAGIC_VMLINUZ=ea05
IMAGE_ROOTFS=rootfs
MAGIC_ROOTFS="0000"
ROOT_DEVICE=/dev/sda

ACTION=$1
IMAGE=$2

[ -z "$ACTION" ] && exit 1
[ -z "$IMAGE" ] && exit 1

# This based on original get_magic_word, but with ability to parse stdin
_get_magic_word()
{
	dd bs=2 count=1 2>/dev/null | hexdump -v -n 2 -e '1/1 "%02x"'
}

_get_vmlinuz()
{
	$GUNZIP -c $IMAGE | $CPIO -i --to-stdout $IMAGE_VMLINUZ
}

_get_rootfs()
{
	$GUNZIP -c $IMAGE | $CPIO -i --to-stdout $IMAGE_ROOTFS
}

platform_check_image()
{
	case "`_get_vmlinuz | _get_magic_word`" in
		$MAGIC_VMLINUZ)
			true
			;;
		*)
			echo "Invalid image type"
			return 1
		;;
	esac
	case "`_get_rootfs | _get_magic_word`" in
		$MAGIC_ROOTFS)
			true
			;;
		*)
			echo "Invalid image type"
			return 1
		;;
	esac
}

platform_do_upgrade()
{
	true
}

_check_partitions()
{
	[ "`$FDISK -l $ROOT_DEVICE | grep "^$ROOT_DEVICE" | wc -l`" = "3" ]
}

DEVICE_LAST=""
DEVICE_SIZE=""
TOTAL_SIZE="`$FDISK -l $ROOT_DEVICE | grep "heads.*sectors.*cylinders" | awk '{print $(NF-1)}'`"
_check_space()
{
	local device_info="`$FDISK -l $ROOT_DEVICE | grep "^${ROOT_DEVICE}2"`"
	DEVICE_LAST="`echo "$device_info" | awk '{print $3}'`"
	DEVICE_SIZE=$(( $DEVICE_LAST - `echo "$device_info" | awk '{print $2}'` ))
	[ $(( $TOTAL_SIZE - $DEVICE_LAST )) -ge $DEVICE_SIZE ]
}

_create_third_partition()
{
	local fdisk_script=`mktemp`
	echo "n" >> $fdisk_script
	echo "p" >> $fdisk_script
	echo "3" >> $fdisk_script
	echo $(( $DEVICE_LAST + 1 )) >> $fdisk_script
	echo $(( $DEVICE_LAST + 1 + $DEVICE_SIZE )) >> $fdisk_script
	echo "w" >> $fdisk_script
	$FDISK $ROOT_DEVICE < $fdisk_script
	rm -f $fdisk_script
}

platform_check_space()
{
	# Check if we already have three partitions
	_check_partitions && return 0
	_check_space && return 1
	_create_third_partition
}

$ACTION $IMAGE
