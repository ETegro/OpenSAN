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
	DEPENDS:=+lua +astor2-einarc +astor2-lua-common +luafilesystem
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
	$(INSTALL_DATA) ./files/astor2/*.lua $(1)/usr/lib/lua/astor2
endef

$(eval $(call BuildPackage,astor2-lua-einarc))
