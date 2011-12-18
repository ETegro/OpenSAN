#
# Copyright (C) 2006-2011 OpenWrt.org
# Copyright (C) 2009-2011 ETegro Technologies, PLC
#                         Sergey Matveev <stargrave@stargrave.org>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

ARCH:=x86_64
BOARD:=x86_64
BOARDNAME:=x86_64
FEATURES:=ext4 targz pci usb x86_64
SUBTARGETS=astor2

LINUX_VERSION:=2.6.32.50

DEVICE_TYPE=

include $(INCLUDE_DIR)/target.mk

$(eval $(call BuildTarget))
