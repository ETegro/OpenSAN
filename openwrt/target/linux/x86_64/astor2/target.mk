BOARDNAME:=aStor2
DEFAULT_PACKAGES += \
	kmod-via-velocity \
	kmod-ata-artop \
	kmod-ata-piix \
	kmod-ata-sil \
	kmod-ata-sil24 \
	kmod-ata-via-sata \
	kmod-ide-core \
	kmod-ide-aec62xx \
	kmod-ide-generic \
	kmod-ide-it821x \
	kmod-ide-pdc202xx \
	kmod-mvsas \
	kmod-3c59x \
	kmod-8139cp \
	kmod-8139too \
	kmod-e100 \
	kmod-e1000 \
	kmod-e1000e \
	kmod-natsemi \
	kmod-ne2k-pci \
	kmod-pcnet32 \
	kmod-r8169 \
	kmod-sis900 \
	kmod-tg3 \
	kmod-via-rhine \
	kmod-mptsas \
	kmod-mpt2sas \
	kmod-igb \
	kmod-ixgbe \
	kmod-cnic \
	kmod-fs-xfs \
	kmod-bonding \
	kmod-ipv6 \
	kmod-usb-hid \
	igb \
	dash \
	gnu-cpio \
	uhttpd \
	astor2-init \
	luci-app-astor2-san \
	astor2-luci-bwc-ipmi-rs230g4 \
	astor2-factory-defaults \
	astor2-var-partition \
	kmod-crypto-core \
	flashcache \
	sysstat \
	apcupsd \
	sgeraser \
	strace \
	luafilesystem \
	xfs-fsck \
	xfs-growfs \
	xfs-mkfs

define Target/Description
	Build firmware images for aStor2 project
endef

