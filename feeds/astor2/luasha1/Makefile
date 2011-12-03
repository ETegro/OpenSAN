#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luasha1
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luasha1
	SUBMENU:=Lua
	SECTION:=lang
	CATEGORY:=Languages
	TITLE:=Lua SHA1 library
	URL:=http://regex.info/blog/lua/sha1
	DEPENDS:=+lua
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luasha1/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_DATA) ./files/*.lua $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,luasha1))
