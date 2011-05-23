#!/bin/sh

IMAGE=$1
IMAGE_VMLINUZ=vmlinuz
MAGIC_VMLINUZ=ea05
IMAGE_ROOTFS=rootfs
MAGIC_ROOTFS="0000"

DD=dd
GUNZIP=gunzip
CPIO=gnu-cpio

[ -z "$IMAGE" ] && exit 1

# This based on original get_magic_word, but with ability to parse stdin
_get_magic_word()
{
	dd bs=2 count=1 2>/dev/null | hexdump -v -n 2 -e '1/1 "%02x"'
}

_get_vmlinuz()
{
	$GUNZIP -c $IMAGE | $CPIO -i $IMAGE_VMLINUZ
}

_get_rootfs()
{
	$GUNZIP -c $IMAGE | $CPIO -i $IMAGE_ROOTFS
}

platform_check_image() {
	[ "$ARGC" -gt 1 ] && return 1

	case "$(get_magic_word "$1")" in
		eb48) return 0;;
		*)
			echo "Invalid image type"
			return 1
		;;
	esac
}

platform_do_upgrade() {
	local ROOTFS
	sync
	grep -q -e "jffs2" -e "squashfs" /proc/cmdline \
		&& ROOTFS="$(awk 'BEGIN { RS=" "; FS="="; } ($1 == "block2mtd.block2mtd") { print substr($2,1,index($2, ",")-1) }' < /proc/cmdline)" \
		|| ROOTFS="$(awk 'BEGIN { RS=" "; FS="="; } ($1 == "root") { print $2 }' < /proc/cmdline)"
	[ -b ${ROOTFS%[0-9]} ] && get_image "$1" > ${ROOTFS%[0-9]}
}
