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
[ "$ACTION" = "platform_check_image" -a -z "$IMAGE" ] && exit 1
[ "$ACTION" = "platform_do_upgrade" -a -z "$IMAGE" ] && exit 1

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
	return 0
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

CURRENT_ROOT=""
_set_current_root()
{
	CURRENT_ROOT="`cat /proc/cmdline | awk '{print $1}' | awk -F= '{print $2}'`"
}

FUTURE_ROOT=""
_set_future_root()
{
	if [ "$CURRENT_ROOT" = "/dev/sda2" ]; then
		FUTURE_ROOT="/dev/sda3"
	else
		FUTURE_ROOT="/dev/sda2"
	fi
}

CURRENT_KERNEL=""
_set_current_kernel()
{
	local mountpoint=`mktemp -d`
	mkdir -p $mountpoint
	mount ${ROOT_DEVICE}1 $mountpoint
	local kernel="`grep $CURRENT_ROOT $mountpoint/boot/grub/menu.lst | awk '{print $2}'`"
	if echo "$kernel" | grep -q failsafe; then
		CURRENT_KERNEL="vmlinuz-failsafe"
	else
		CURRENT_KERNEL="vmlinuz"
	fi
	umount $mountpoint
	rmdir $mountpoint
}

FUTURE_KERNEL=""
_set_future_kernel()
{
	if [ "$CURRENT_KERNEL" = "vmlinuz" ]; then
		FUTURE_KERNEL="vmlinuz-failsafe"
	else
		FUTURE_KERNEL="vmlinuz"
	fi
}

_flash_rootfs()
{
	_get_rootfs > $FUTURE_ROOT
}

_flash_kernel()
{
	local mountpoint=`mktemp -d`
	mkdir -p $mountpoint
	mount ${ROOT_DEVICE}1 $mountpoint
	cp $mountpoint/boot/$CURRENT_KERNEL $mountpoint/boot/$FUTURE_KERNEL
	_get_vmlinuz > $mountpoint/boot/$CURRENT_KERNEL
	cat > $mountpoint/boot/grub/menu.lst <<__EOF__
serial --unit=0 --speed=38400 --word=8 --parity=no --stop=1
terminal --timeout=2 console serial

default 0
timeout 5

title   OpenSAN
root    (hd0,0)
kernel  /boot/$CURRENT_KERNEL root=$FUTURE_ROOT rootfstype=ext4 rootwait console=tty0 console=ttyS0,38400n8 noinitrd reboot=bios
boot

title	OpenSAN (failsafe)
root	(hd0,0)
kernel  /boot/$FUTURE_KERNEL root=$CURRENT_ROOT rootfstype=ext4 rootwait console=tty0 console=ttyS0,38400n8 noinitrd reboot=bios
boot
__EOF__
	umount $mountpoint
	rmdir $mountpoint
}

platform_do_upgrade()
{
	#TODO: races prevention
	_set_current_root
	_set_future_root
	_set_current_kernel
	_set_future_kernel
	_flash_rootfs
	_flash_kernel
	sync
}

platform_copy_config()
{
	_set_current_root
	_set_future_root
	local mountpoint=`mktemp -d`
	mkdir -p $mountpoint
	mount $FUTURE_ROOT $mountpoint
	cp "$CONF_TAR" $mountpoint
	rm -f $mountpoint/etc/uci-defaults/*
	umount $mountpoint
	rmdir $mountpoint
	sync
}

$ACTION $IMAGE
