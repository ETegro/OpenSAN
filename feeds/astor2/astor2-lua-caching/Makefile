#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-lua-caching
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-lua-caching
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Caching policy-related bindings
	URL:=http://www.opensan.org/
	DEPENDS:=+astor2-lua-common +astor2-lua-scst +astor2-lua-einarc +astor2-lua-lvm
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-lua-caching/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/astor2
	$(INSTALL_DIR) $(1)/etc/init.d

	$(INSTALL_DATA) ./files/astor2/*.lua $(1)/usr/lib/lua/astor2
	$(INSTALL_BIN) ./files/astor2-lua-caching.init $(1)/etc/init.d/astor2-lua-caching
endef

$(eval $(call BuildPackage,astor2-lua-caching))
