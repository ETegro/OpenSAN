#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=multipath-tools
PKG_VERSION:=0.4.9
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=http://christophe.varoqui.free.fr/multipath-tools
PKG_MD5SUM:=a6d4b48afc28f1f50f5ee4b1b06d2765

include $(INCLUDE_DIR)/package.mk

define Package/multipath-tools
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Maintain multipath block device access
	URL:=http://christophe.varoqui.free.fr/
	DEPENDS:=+udev +kmod-dm +libaio +libdevmapper
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Package/multipath-tools/description
	These tools are in charge of maintaining the disk multipath
	device maps and react to path and map events.
endef

TAR_CMD=$(HOST_TAR) -C $(1) $(TAR_OPTIONS)

define Build/Configure
	CPPFLAGS="$(TARGET_CPPFLAGS) -I$(PKG_BUILD_DIR)/libmultipath" \
	LDFLAGS="$(TARGET_LDFLAGS) -L$(PKG_BUILD_DIR)/libmultipath" \
	STAGING_DIR="$(STAGING_DIR)" \
	sh files/patch_makefiles.sh $(PKG_BUILD_DIR)
endef

define Build/Compile
	$(MAKE_VARS) $(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS)
	$(MAKE_VARS) $(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_FLAGS) DESTDIR=$(STAGING_DIR) install
endef

define Package/multipath-tools/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_DIR) $(1)/lib
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/lib/multipath
	ln -s "/lib" $(1)/lib64
	$(INSTALL_BIN) $(STAGING_DIR)/sbin/multipath* $(1)/sbin/
	$(INSTALL_BIN) $(STAGING_DIR)/sbin/kpartx $(1)/sbin/
	$(INSTALL_BIN) $(STAGING_DIR)/lib64/libmultipath.so* $(1)/lib/
	$(INSTALL_BIN) $(STAGING_DIR)/lib64/multipath/* $(1)/lib/multipath
	$(INSTALL_BIN) ./files/multipathd.init $(1)/etc/init.d/multipathd
endef

$(eval $(call BuildPackage,multipath-tools))
