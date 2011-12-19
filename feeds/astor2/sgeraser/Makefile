#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sgeraser
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/sgeraser
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Zeroing and secure wiping disk utility
	URL:=http://www.opensan.org/
	DEPENDS:=+perlbase-fcntl +perlbase-digest +perlbase-posix +perlbase-integer +perlbase-dynaloader
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/sgeraser/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/sgeraser $(1)/usr/bin
endef

$(eval $(call BuildPackage,sgeraser))
