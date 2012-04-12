#
# Copyright (C) 2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-var-partition
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-var-partition
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Separate /var partition creation
	URL:=http://www.opensan.org/
	DEPENDS:=+fdisk +xfs-mkfs
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-var-partition/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/astor2-var-partition.init $(1)/etc/init.d/astor2-var-partition
endef

$(eval $(call BuildPackage,astor2-var-partition))
