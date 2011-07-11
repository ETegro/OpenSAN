include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=iscsi-scst-userspace
PKG_REV:=3672
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
                 +perlbase-getopt \
                 +perlbase-io \
                 +perlbase-essential \
                 +perlbase-class \
                 +perlbase-fcntl \
                 +perlbase-symbol \
                 +perlbase-posix \
                 +perlbase-config \
                 +perlbase-text \
                 +perlbase-cwd \
                 +perlbase-xsloader \
                 +perlbase-errno \
                 +perlbase-ipc \
                 +perlbase-locale \
                 +perlbase-module \
                 +perlbase-params \
                 +perlbase-filehandle \
                 +perlbase-file \
                 +perlbase-tie \
                 +perlbase-selectsaver \
                 +perlbase-socket \
                 +perlbase-autoloader
endef

define Build/Compile
	$(MAKE) -C "$(PKG_BUILD_DIR)" \
		KDIR="$(LINUX_DIR)" \
		CC="$(TARGET_CC)" \
		scstadm \
		scst \
		iscsi
endef

define Package/iscsi-scst-userspace/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/lib/perl5/5.10/SCST
	
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iscsi-scst/usr/iscsi-scst-adm $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iscsi-scst/usr/iscsi-scstd $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scstadmin/scstadmin/scstadmin $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/scst.init $(1)/etc/init.d/scst
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/scstadmin/scstadmin/scst-0.9.00/lib/SCST/SCST.pm $(1)/usr/lib/perl5/5.10/SCST
endef

$(eval $(call BuildPackage,iscsi-scst-userspace))
