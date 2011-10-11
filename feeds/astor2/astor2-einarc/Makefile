#
# Copyright (C) 2011 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=astor2-einarc
PKG_REV:=1958
PKG_VERSION:=svn$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=https://inq.svn.sourceforge.net/svnroot/inq/trunk/client/lib/einarc
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/astor2-einarc
	SECTION:=astor2
	CATEGORY:=aStor2
	TITLE:=Inquisitor's Einarc
	URL:=http://www.inquisitor.ru/doc/einarc/
	DEPENDS:=+ruby +ruby-core +librt \
		+udev +mdadm +smartmontools \
		+kmod-md-mod +kmod-md-linear \
		+kmod-md-raid0 +kmod-md-raid1 \
		+kmod-md-raid10 +kmod-md-raid456 \
		+sdparm +sg3_utils
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Configure
	(cd $(PKG_BUILD_DIR); ./configure \
		--modules=software \
		--bindir=/usr/bin \
		--rubysharedir=/usr/lib/ruby/site_ruby/1.9/raid \
		--einarcvardir=/usr/var/lib/einarc \
		--einarclibdir=/usr/var/lib/einarc/tools )
endef

define Package/astor2-einarc/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib/ruby/site_ruby/1.9/raid
	$(INSTALL_DIR) $(1)/usr/lib/ruby/site_ruby/1.9/raid/extensions
	$(INSTALL_DIR) $(1)/usr/var/lib/einarc
	$(INSTALL_DIR) $(1)/usr/var/lib/einarc/tools
	$(INSTALL_DIR) $(1)/etc/init.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/einarc $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/einarc-install $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/raid-wizard-passthrough $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/raid-wizard-optimal $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/raid-wizard-clear $(1)/usr/bin
	$(INSTALL_BIN) ./files/einarc.init $(1)/etc/init.d/einarc

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/raid/*.rb $(1)/usr/lib/ruby/site_ruby/1.9/raid
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/raid/extensions/hotspare.rb $(1)/usr/lib/ruby/site_ruby/1.9/raid/extensions
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/config.rb $(1)/usr/var/lib/einarc
endef

$(eval $(call BuildPackage,astor2-einarc))
