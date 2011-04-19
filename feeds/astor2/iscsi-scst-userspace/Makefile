
include $(TOPDIR)/rules.mk

PKG_NAME:=iscsi-scst-userspace
PKG_REV:=3263
PKG_VERSION:=svn$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=https://scst.svn.sourceforge.net/svnroot/scst/branches/2.0.0.x
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/iscsi-scst-userspace
	SECTION:=admin
	CATEGORY:=Administration
	TITLE:=SCST iSCSI target userspace programs
	URL:=http://scst.sourceforge.net/
	DEPENDS:=+kmod-iscsi-scst \
		 +perl \
	         +perlbase-file \
	         +perlbase-getopt \
	         +perlbase-io
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		scstadm \
		iscsi
endef

define Package/iscsi-scst-userspace/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_BUILD_DIR)/iscsi-scst/usr/iscsi-scst-adm $(1)/usr/sbin/
	$(CP) $(PKG_BUILD_DIR)/iscsi-scst/usr/iscsi-scstd $(1)/usr/sbin/
	$(CP) $(PKG_BUILD_DIR)/scstadmin/scstadmin/scstadmin $(1)/usr/sbin/
	$(CP) $(PKG_BUILD_DIR)/scstadmin/scstadmin/scst-0.9.00/lib/SCST/SCST.pm $(1)/usr/lib/perl5/5.10/
endef

$(eval $(call BuildPackage,iscsi-scst-userspace))
