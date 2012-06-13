#
# Copyright (C) 2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=flashcache
PKG_REV:=67a11d7ef7bbb26c8f1be5113451c65a7d973b24
PKG_VERSION=git$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=git://github.com/facebook/flashcache.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/flashcache
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=General purpose writeback block cache
	URL:=https://github.com/facebook/flashcache
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE_VARS) $(MAKE) -C $(PKG_BUILD_DIR) KERNEL_TREE=$(LINUX_DIR) $(MAKE_FLAGS)
endef

define Package/flashcache/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/lib/modules
	$(INSTALL_DIR) $(1)/etc/init.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/utils/flashcache_create $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/utils/flashcache_load $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/utils/flashcache_destroy $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/flashcache.ko $(1)/lib/modules
	$(INSTALL_BIN) files/flashcache.init $(1)/etc/init.d/flashcache
endef

$(eval $(call BuildPackage,flashcache))
