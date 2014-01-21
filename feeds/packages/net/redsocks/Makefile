#
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=redsocks
PKG_VERSION:=0.4
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/darkk/redsocks.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=a9cfd090119385a1ef973baf94342a2db20595b9
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/redsocks
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  DEPENDS:=+libevent2
  TITLE:=Redirect any TCP connection to a SOCKS or HTTPS proxy server
endef

define Package/redsocks/description
  Redsocks is a daemon running on the local system, that will transparently
  tunnel any TCP connection via a remote SOCKS4, SOCKS5 or HTTP proxy server. It
  uses the system firewall's redirection facility to intercept TCP connections,
  thus the redirection is system-wide, with fine-grained control, and does
  not depend on LD_PRELOAD libraries.

  Redsocks supports tunneling TCP connections and UDP packets. It has
  authentication support for both, SOCKS and HTTP proxies.

  Also included is a small DNS server returning answers with the "truncated" flag
  set for any UDP query, forcing the resolver to use TCP.
endef

define Package/redsocks/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/redsocks $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/redsocks.init $(1)/etc/init.d/redsocks
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/redsocks.conf.example $(1)/etc/redsocks.conf
endef

$(eval $(call BuildPackage,redsocks))
