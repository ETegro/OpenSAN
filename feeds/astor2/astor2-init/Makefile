#
# Copyright (C) 2011-2012 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-lua-einarc
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-init
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=OpenSAN's main initialization script
	URL:=http://www.opensan.org
	DEPENDS:=+astor2-blockdev-parameters +astor2-lua-einarc \
		+astor2-lua-caching \
		+astor2-lua-lvm astor2-lua-scst
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-init/install
	$(INSTALL_DIR) $(1)/lib/modules
	$(INSTALL_DIR) $(1)/etc/hotplug.d/block
	$(INSTALL_DIR) $(1)/etc/init.d
	ln -s /lib/modules/3.10.26 $(1)/lib/modules/3.10.26
	ln -s /lib/modules/3.10.26 $(1)/lib/modules/3.10.26+
	ln -s /tmp/20-hotspares $(1)/etc/hotplug.d/block/
	ln -s /tmp/30-blockdevparams $(1)/etc/hotplug.d/block/
	$(INSTALL_BIN) ./files/astor2.init $(1)/etc/init.d/astor2-init
endef

$(eval $(call BuildPackage,astor2-init))
