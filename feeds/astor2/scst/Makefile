include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=scst
PKG_REV:=3837
PKG_VERSION:=svn$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=https://scst.svn.sourceforge.net/svnroot/scst/branches/2.1.0.x
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

SCST_MENU:=SCST support

define KernelPackage/scst
	SUBMENU:=$(SCST_MENU)
	TITLE:=Generic SCSI target subsystem for Linux (SCST)
	FILES:=$(PKG_BUILD_DIR)/scst/src/dev_handlers/*.$(LINUX_KMOD_SUFFIX) $(PKG_BUILD_DIR)/scst/src/scst.$(LINUX_KMOD_SUFFIX)
	AUTOLOAD=$(call AutoLoad,70, scst scst_cdrom scst_changer scst_disk scst_modisk scst_tape scst_vdisk scst_raid scst_processor scst_user)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		KDIR="$(LINUX_DIR)" \
		scst \
		iscsi
endef

$(eval $(call KernelPackage,scst))

define KernelPackage/iscsi-scst
	SUBMENU:=$(SCST_MENU)
	TITLE:=SCST iSCSI target
	DEPENDS:=+kmod-scst +kmod-lib-crc32c
	KCONFIG:=CONFIG_TCP_ZERO_COPY_TRANSFER_COMPLETION_NOTIFICATION=y
	FILES:=$(PKG_BUILD_DIR)/iscsi-scst/kernel/iscsi-scst.$(LINUX_KMOD_SUFFIX)
	AUTOLOAD=$(call AutoLoad,71,iscsi-scst)
endef

#define Build/Compile
#        $(MAKE) -C $(PKG_BUILD_DIR) \
#                iscsi
#endef

$(eval $(call KernelPackage,iscsi-scst))
