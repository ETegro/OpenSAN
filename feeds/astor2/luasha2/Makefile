#
# Copyright (C) 2011 Sergey Matveev (stargrave@stargrave.org)
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luasha2
PKG_VERSION:=0.2.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

PKG_SOURCE:=sha2-$(PKG_VERSION).zip
PKG_SOURCE_URL:=http://sha2.googlecode.com/hg/
PKG_MD5SUM:=ee59eef03995fb93ed3a5e4acbd1883c

PKG_UNPACK:=unzip -d $(PKG_BUILD_DIR) $(DL_DIR)/$(PKG_SOURCE)

include $(INCLUDE_DIR)/package.mk

define Package/luasha2
	SUBMENU:=Lua
	SECTION:=lang
	CATEGORY:=Languages
	TITLE:=Lua SHA2 library
	URL:=https://code.google.com/p/sha2/
	DEPENDS:=+lua
	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
endef

define Build/Prepare
	$(PKG_UNPACK)
endef

define Build/Configure
endef

SHA2_DEFINES=-DSHA2_USE_INTTYPES_H -DBYTE_ORDER -DLITTLE_ENDIAN

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) $(FPIC) \
		-I$(STAGING_DIR)/usr/include/ \
		-I$(PKG_BUILD_DIR)/sha2-$(PKG_VERSION)/ \
		-c $(PKG_BUILD_DIR)/sha2-$(PKG_VERSION)/sha2.c \
		-o $(PKG_BUILD_DIR)/sha2.o \
		$(SHA2_DEFINES)
	$(TARGET_CC) $(TARGET_CFLAGS) $(FPIC) \
		-I$(STAGING_DIR)/usr/include/ \
		-I$(PKG_BUILD_DIR)/sha2-$(PKG_VERSION)/ \
		-c $(PKG_BUILD_DIR)/sha2-$(PKG_VERSION)/sha2lib.c \
		-o $(PKG_BUILD_DIR)/sha2lib.o \
		$(SHA2_DEFINES)
	$(TARGET_CC) -shared \
		-o $(PKG_BUILD_DIR)/sha2.so \
		-L$(STAGING_DIR)/usr/lib/ \
		$(PKG_BUILD_DIR)/sha2.o $(PKG_BUILD_DIR)/sha2lib.o
endef

define Package/luasha2/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sha2.so $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,luasha2))
