#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-lua-einarc
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-lua-einarc
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Lua binding for Inquisitor's Einarc
	URL:=http://www.inquisitor.ru/doc/einarc/
	DEPENDS:=+lua +astor2-lua-common +luafilesystem +librt +udev \
		+mdadm +smartmontools +kmod-md-mod +kmod-md-linear \
		+kmod-md-raid0 +kmod-md-raid1 +kmod-md-raid10 \
		+kmod-md-raid456 +sdparm +sg3_utils +hdparm +luasha2
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-lua-einarc/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/astor2
	$(INSTALL_DIR) $(1)/etc/hotplug.d/block/preboot
	$(INSTALL_DATA) ./files/astor2/*.lua $(1)/usr/lib/lua/astor2
	$(INSTALL_DATA) ./files/hotplug.d/* $(1)/etc/hotplug.d/block/preboot
endef

$(eval $(call BuildPackage,astor2-lua-einarc))
