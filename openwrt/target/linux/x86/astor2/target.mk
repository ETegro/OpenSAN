BOARDNAME:=aStor2
FEATURES:=squashfs pci usb
DEFAULT_PACKAGES += kmod-via-velocity kmod-ata-artop kmod-ata-nvidia-sata \
                    kmod-ata-piix kmod-ata-sil kmod-ata-sil24 kmod-ata-via-sata \
                    kmod-ide-core kmod-ide-aec62xx kmod-ide-generic kmod-ide-it821x \
                    kmod-ide-pdc202xx kmod-mvsas kmod-3c59x kmod-8139cp kmod-8139too \
                    kmod-e100 kmod-e1000 kmod-e1000e kmod-natsemi kmod-ne2k-pci \
                    kmod-pcnet32 kmod-r8169 kmod-sis900 kmod-tg3 kmod-via-rhine \
					kmod-mptsas

define Target/Description
	Build firmware images for aStor2 project
endef

