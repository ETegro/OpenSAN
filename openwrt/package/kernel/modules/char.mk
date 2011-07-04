#
# Copyright (C) 2011 Sergey Matveev (stargrave@stargrave.org)
#

CHAR_MENU:=Character Devices

define KernelPackage/ipmi
	SUBMENU:=$(CHAR_MENU)
	TITLE:=IPMI remote computer management system
	KCONFIG:= \
		CONFIG_IPMI_HANDLER \
		CONFIG_IPMI_SI \
		CONFIG_IPMI_DEVICE_INTERFACE
	FILES:=$(LINUX_DIR)/drivers/char/ipmi/ipmi_*.ko
	AUTOLOAD:=$(call AutoLoad,30,ipmi_msghandler ipmi_si ipmi_devintf)
endef

$(eval $(call KernelPackage,ipmi))
