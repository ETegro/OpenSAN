#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=cpio
PKG_VERSION:=2.11
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://ftp.gnu.org/gnu/cpio
PKG_MD5SUM:=1112bb6c45863468b5496ba128792f6c

include $(INCLUDE_DIR)/package.mk

define Package/gnu-cpio
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=GNU cpio archiver
	URL:=http://www.gnu.org/software/cpio/
endef

define Package/gnu-cpio/description
	GNU cpio copies files into or out of a cpio or tar archive. The archive
	can be another file on the disk, a magnetic tape, or a pipe.
endef

define Package/gnu-cpio/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/cpio $(1)/usr/bin/gnu-cpio
endef

$(eval $(call BuildPackage,gnu-cpio))
