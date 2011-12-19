#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-blockdev-parameters
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-blockdev-parameters
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Different hard drive performance tweaks
	URL:=http://www.opensan.org/
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-blockdev-parameters/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/astor2-blockdev-parameters.init $(1)/etc/init.d/astor2-blockdev-parameters
endef

$(eval $(call BuildPackage,astor2-blockdev-parameters))
