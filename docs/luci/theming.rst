.. _luci-theming:

================
Собственная тема
================

В исходном коде
===============
:Шаблоны:
 * /feeds/luci/themes/astor2/luasrc/view/astor2/header.htm
 * /feeds/luci/themes/astor2/luasrc/view/astor2/footer.htm
 * /feeds/luci/applications/luci-astor2-san/luasrc/view/san.htm
 * /feeds/luci/applications/luci-astor2-san/luasrc/view/san/\*
:Статические файлы:
 * /feeds/luci/themes/astor2/htdocs/luci-static/astor2/css/
 * /feeds/luci/themes/astor2/htdocs/luci-static/astor2/js/
 * /feeds/luci/themes/openwrt/htdocs/luci-static/openwrt.org/ --
   **не модифицировать**

В образе
========
:Шаблоны:
 * /usr/lib/lua/luci/view/themes/astor2/header.htm
 * /usr/lib/lua/luci/view/themes/astor2/footer.htm
 * /usr/lib/lua/luci/view/san.htm
 * /usr/lib/lua/luci/view/san/\*
:Статические файлы:
 * /www/luci-static/astor2/css/
 * /www/luci-static/astor2/js/
 * /www/luci-static/openwrt.org/ -- **не модифицировать**

openwrt.org связанные вещи можно использовать за основу, но
модифицировать не надо.
