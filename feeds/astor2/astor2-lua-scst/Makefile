#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-lua-scst
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-lua-scst
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=SCST Lua bindings for aStor2 project
	URL:=http://www.opensan.org/
	DEPENDS:=+lua +iscsi-scst-userspace +astor2-lua-common +luafilesystem
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-lua-scst/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/astor2
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/astor2/*.lua $(1)/usr/lib/lua/astor2
	$(INSTALL_CONF) ./files/scst.config $(1)/etc/config/scst
endef

$(eval $(call BuildPackage,astor2-lua-scst))
