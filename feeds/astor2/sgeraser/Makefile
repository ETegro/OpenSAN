#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sgeraser
PKG_REV:=40d73e0d937cd067f80fdd98f0a688d18f1e1f98
PKG_VERSION=git$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=git://github.com/stargrave/sgeraser.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/sgeraser
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Zeroing and secure wiping disk utility
	URL:=http://www.opensan.org/
	DEPENDS:=+perlbase-fcntl +perlbase-digest +perlbase-posix +perlbase-integer +perlbase-dynaloader
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/sgeraser/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sgeraser $(1)/usr/bin
endef

$(eval $(call BuildPackage,sgeraser))
