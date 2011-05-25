USE_REFRESH=1
LIBRARY_PATH=/lib/upgrade/astor2/platform.sh

platform_check_image() {
	exec $LIBRARY_PATH platform_check_image "$1"
}

platform_do_upgrade() {
	exec $LIBRARY_PATH platform_do_upgrade "$1"
}

x86_prepare_ext2() {
	# if we're running from ext2, we need to make sure that we have a mtd 
	# partition that points to the active rootfs partition.
	# however this only matters if we actually need to preserve the config files
	[ "$SAVE_CONFIG" -eq 1 ] || return 0
	grep rootfs /proc/mtd >/dev/null || {
		echo /dev/hda2,65536,rootfs > /sys/module/block2mtd/parameters/block2mtd
	}
}
#append sysupgrade_pre_upgrade x86_prepare_ext2
