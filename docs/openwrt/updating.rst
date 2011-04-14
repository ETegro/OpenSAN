.. _openwrt-updating:

==========
Обновление
==========

Для обновления OpenWRT среза имеющегося у нас в *openwrt/* директории,
необходимо следующее:

* Перейти в ветку **updates**::

  > git checkout updates

* Если директория *openwrt/* не имеет Subversion метаинформации, то её
  необходимо создать, например заново выполнив *svn checkout*. SVN пути
  можно найти в *README* файле::

  > rm -fr openwrt/
  > svn checkout -rXXXXX svn://.../openwrt/trunk openwrt

* Закоммитить изменения/обновления::

  > git commit -m "Updated OpenWRT to XXXXX" -a

* Произвести слияние ветки **updates** с master-ом (или другой ветки в
  которой производится разработка)::

  > git checkout master
  > git merge updates
