# 
# Copyright (C) 2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sg3_utils
PKG_VERSION:=1.31
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tgz
PKG_SOURCE_URL:=http://sg.danny.cz/sg/p/
PKG_MD5SUM:=9431e1944cde829a24dedf027e1364b5

include $(INCLUDE_DIR)/package.mk

define Package/sg3_utils
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=+kmod-scsi-generic
  TITLE:=sg3 scsi utilities
  URL:=http://sg.danny.cz/sg/sg3_utils.html
endef

define Package/sg3_utils/description
  The package includes a number of utilities to allow a user
  to use the sg interface to find out low-level information
  about any SCSI device.
endef

define Package/sg3_utils/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/.libs/sg_start $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/.libs/sg_ses $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/.libs/sg_inq $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/.libs/sginfo $(1)/usr/bin

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/lib/.libs/libsgutils2.so* $(1)/usr/lib
endef

$(eval $(call BuildPackage,sg3_utils))
