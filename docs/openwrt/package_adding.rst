.. _openwrt-package_adding:

=================
Добавление пакета
=================

Добавление дополнительных команд, программ, просто файлов, и всего
всего такого обеспечивается пакетами. Пакет -- это правило как что
и куда установить и выполнить.

Всё, начиная от базовых файлов в */etc*, ядра и заканчивая списком
временных зон в */usr/share* является пакетами. В OpenWRT используется
система **opkg**. По сути аналогична **apt-get**, но сильно урезана
и не требовательна к ресурсам. Файлы пакетов имеют расширение **.ipk**.

В OpenWRT все пакеты берутся из **feed**-ов: некие абстрактные
источники их. feed-ом может быть локальная директория, URL-и в
Интернете, ссылки на Subversion или Git репозитории, итд.

Пример структуры feed-а::

  somefeed+
          | somepackage1
          | somepackage2
          | somepackage3
          \ ...

Каждый пакет находится в своей отдельной директории. В каждой
директории имеется Makefile объясняющий OpenWRT системе сборки что
делать с этим пакетом: какие пункты добавить в меню конфигурирования
OpenWRT, какие зависимости от других пакетов появляются, как добыть
исходный код если это необходимо, как выполнить конфигурирование пакета
(./configure), его сборку и установку.

Примером элементарного пакета выполняющего скачивание исходного кода,
конфигурирование и установку является astor2-einarc. Доступный в
**astor2-feed/astor2-einarc/** директории.

Рассмотрим его код::

  include $(TOPDIR)/rules.mk
  [...]
  include $(INCLUDE_DIR)/package.mk
  [...]
  $(eval $(call BuildPackage,astor2-einarc))

Это обязательные поля реализующие возможность обработки этого файла
системой сборки OpenWRT.

::

  PKG_NAME:=astor2-einarc
  PKG_REV:=1880
  PKG_VERSION:=svn$(PKG_REV)
  PKG_RELEASE:=1

Здесь задаются имя пакета, используемая версия из Subversion
репозитория.

::

  PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
  PKG_SOURCE_URL:=https://inq.svn.sourceforge.net/svnroot/inq/trunk/client/lib/einarc
  PKG_SOURCE_PROTO:=svn
  PKG_SOURCE_VERSION:=$(PKG_REV)
  PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

Здесь задаётся URL репозитория, говорится что это Subversion.

::

  define Package/astor2-einarc
  	SECTION:=astor2
  	CATEGORY:=aStor2
  	TITLE:=Inquisitor's Einarc for aStor
  	URL:=http://www.inquisitor.ru/doc/einarc/
  	DEPENDS:=+ruby +ruby-core +librt \
  		+udev +mdadm +smartmontools \
  		+kmod-md-mod +kmod-md-linear \
  		+kmod-md-raid0 +kmod-md-raid1 \
  		+kmod-md-raid10 +kmod-md-raid456
  	MAINTAINER:=Sergey Matveev <stargrave@stargrave.org>
  endef

Создание новой секции **aStor2** в меню конфигурации OpenWRT и
создание в нём возможности выбора пакета установки einarc. Также
задаются зависимости от сторонних пакетов.

::

  define Build/Configure
  	(cd $(PKG_BUILD_DIR); ./configure \
  		--modules=software \
  		--bindir=/usr/bin \
  		--rubysharedir=/usr/lib/ruby/site_ruby/1.9/raid \
  		--einarcvardir=/usr/var/lib/einarc \
  		--einarclibdir=/usr/var/lib/einarc/tools )
  endef

Правила конфигурирования пакета. Необходимо вызвать ./configure
скрипт, не являющийся основанных на autoconf утилитах, и указать ему
используемый *software* модуль и конкретные директории установки.

::

  define Package/astor2-einarc/install
  	$(INSTALL_DIR) $(1)/usr/bin
        [...]
  	$(INSTALL_DATA) $(PKG_BUILD_DIR)/config.rb $(1)/usr/var/lib/einarc
  endef

Правила описывающие какие куда файлы необходимо поставить с
соответствующими правами доступа и директории создать.

Данный Makefile достаточен для полноценной установки Einarc-а в сборку
дистрибутива OpenWRT. Чтобы появилась возможность "подхватить" данный
*astor2* feed и пометить пакет *astor2-einarc* для установки необходимо
добавить ссылку на данный feed в *openwrt/trunk/feeds.conf.default*::

  src-link astor2 /home/stargrave/astor2-feed

Эта ссылка на feed в пределах файловой системы.

Далее необходимо выполнить скачивание feed-а (если он находится в
Subversion или Git-е например) и обновление метаинформации о пакетах::

  % cd openwrt/trunk
  % ./scripts/feeds update astor2
  % ./scripts/feeds install -a -p astor2

