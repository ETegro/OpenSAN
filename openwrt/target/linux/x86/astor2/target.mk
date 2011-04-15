BOARDNAME:=aStor2
FEATURES:=squashfs pci usb
DEFAULT_PACKAGES += kmod-via-rhine kmod-via-velocity kmod-ata-artop \
                    mod-ata-nvidia-sata mod-ata-piix mod-ata-sil \
		    mod-ata-sil24 mod-ata-via-sata mod-ide-core \
		    mod-ide-aec62xx mod-ide-generic mod-ide-it821x \
		    mod-ide-pdc202xx mod-mvsas kmod-3c59x mod-8139cp \
		    mod-8139too mod-e100 mod-e1000 mod-e1000e mod-natsemi \
		    mod-ne2k-pci mod-pcnet32 mod-r8169 mod-sis900 mod-tg3 \
		    mod-via-rhine mod-via-velocity

define Target/Description
	Build firmware images for aStor2 project
endef

