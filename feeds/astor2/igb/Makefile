#
# Copyright (C) 2011-2012 Vladimir Petukhov (vladimir.petukhov@etegro.com)
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=igb
PKG_RELEASE:=1
PKG_VERSION:=5.0.6

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://downloadmirror.intel.com/13663/eng
PKG_MD5SUM:=701717fbbba6065af4ff5138bd3a3a9c

include $(INCLUDE_DIR)/package.mk

define Package/igb
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Ethernet igb driver
	URL:=http://downloadmirror.intel.com/13663/eng/igb-5.0.6.tar.gz
	MAINTAINER:=Vladimir Petukhov (vladimir.petukhov@etegro.com)
endef

define Package/igb/description
	Network Adapter Driver for 82575/6, 82580, and I350-Based
	Gigabit Network Connections for Linux
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE_VARS) KERNEL_DIR="$(LINUX_DIR)" $(MAKE) -C $(PKG_BUILD_DIR)/src $(MAKE_FLAGS)
endef

define Package/igb/install
	$(INSTALL_DIR) $(1)/lib/modules
	$(INSTALL_DIR) $(1)/etc/init.d

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/igb.ko $(1)/lib/modules
	$(INSTALL_BIN) files/igb.init $(1)/etc/init.d/igb
endef

$(eval $(call BuildPackage,igb))
