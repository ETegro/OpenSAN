#
# Copyright (C) 2011-2012 Vladimir Petukhov (vladimir.petukhov@etegro.com)
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=igb
PKG_RELEASE:=1
PKG_VERSION:=3.3.6

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://downloadcenter.intel.com/detail_desc.aspx?agr=Y&DwnldID=13663
PKG_MD5SUM:=b9267beb43f41d364f73b4d5b9040f1e

include $(INCLUDE_DIR)/package.mk

define Package/igb
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Ethernet igb driver
	URL:=http://downloadcenter.intel.com/detail_desc.aspx?agr=Y&DwnldID=13663
	MAINTAINER:=Vladimir Petukhov (vladimir.petukhov@etegro.com)
endef

#define Package/multipath-tools/description
	#These tools are in charge of maintaining the disk multipath
	#device maps and react to path and map events.
#endef

define Build/Configure
endef

define Build/Compile
	$(MAKE_VARS) KERNEL_DIR="$(LINUX_DIR)" $(MAKE) -C $(PKG_BUILD_DIR)/src $(MAKE_FLAGS)
endef

define Package/igb/install
	$(INSTALL_DIR) $(1)/lib/modules
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/igb.ko $(1)/lib/modules
endef

$(eval $(call BuildPackage,igb))
