#
# Copyright (C) 2011 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-luci-bwc-ipmi
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-bwc-ipmi/Default
	SUBMENU:=luci-bwc-ipmi
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=IPMI LuCI BWC-like daemon
	URL:=http://www.opensan.org/
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Package/astor2-luci-bwc-ipmi
$(call Package/astor2-luci-bwc-ipmi/Default)
	TITLE:=IPMI LuCI BWC-like daemon
	DEPENDS:=+perl +ipmitool +kmod-ipmi
endef

define Package/astor2-luci-bwc-ipmi-rs230g3
$(call Package/astor2-luci-bwc-ipmi/Default)
	TITLE:+= (RS230 G3 profile)
	DEPENDS:=+astor2-luci-bwc-ipmi
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/astor2-luci-bwc-ipmi/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d

	$(INSTALL_BIN) ./files/luci-bwc-ipmi $(1)/usr/bin
	$(INSTALL_BIN) ./files/astor2-luci-bwc-ipmi.init $(1)/etc/init.d/astor2-luci-bwc-ipmi
endef

define Package/astor2-luci-bwc-ipmi-rs230g3/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/san_monitoring

	$(INSTALL_CONF) ./files/rs230g3/configuration.lua $(1)/usr/lib/lua/luci/controller/san_monitoring_configuration.lua
	$(INSTALL_DATA) ./files/rs230g3/front.svg.htm $(1)/usr/lib/lua/luci/view/san_monitoring
	$(INSTALL_DATA) ./files/rs230g3/rear.svg.htm $(1)/usr/lib/lua/luci/view/san_monitoring
	$(INSTALL_DATA) ./files/rs230g3/motherboard.svg.htm $(1)/usr/lib/lua/luci/view/san_monitoring
endef

$(eval $(call BuildPackage,astor2-luci-bwc-ipmi))
