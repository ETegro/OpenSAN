#
# Copyright (C) 2011 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-factory-defaults
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-factory-defaults
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Factory defaults utility for aStor2 project
	URL:=http://www.opensan.org/
	DEPENDS:=+astor2-lua-einarc +astor2-lua-lvm +astor2-lua-scst
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-factory-defaults/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/share/opensan-factory-defaults
	$(INSTALL_BIN) ./files/opensan-factory-defaults $(1)/usr/bin
	$(INSTALL_DATA) ./files/clearing.lua $(1)/usr/share/opensan-factory-defaults
endef

$(eval $(call BuildPackage,astor2-factory-defaults))
