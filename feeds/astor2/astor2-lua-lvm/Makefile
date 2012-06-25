#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-lua-lvm
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-lua-lvm
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Lua binding for LVM2
	URL:=http://www.opensan.org/
	DEPENDS:=+lua +lvm2 +astor2-lua-common +astor2-lua-einarc
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-lua-lvm/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/astor2
	$(INSTALL_DATA) ./files/astor2/*.lua $(1)/usr/lib/lua/astor2
endef

$(eval $(call BuildPackage,astor2-lua-lvm))
