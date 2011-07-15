.. _luci-translation:

==============================
Интернационализация приложений
==============================

.. contents::

Система i18n (internationalization) построена полностью на системе GNU
gettext.  Соответственно необходимо что-то генерирующее PortableObject
файлы (.po), их шаблоны (.pot) и собственно сами готовые файлы
переводов.

Сгенерировать POT-файл можно следующим образом::

  ./build/i18n-scan.pl applications/luci-astor2-san applications/luci-astor2-san-monitoring ../astor2/astor2-luci-bwc-ipmi/files/rs230g3 > po/templates/astor2_san.pot

Обновить шаблон можно следующим образом::

  ./build/i18n-update.pl po astor2_san.po

Во время создания IPK пакета приложения LuCI будут сгенерированы
автоматически и их бинарные представления
(`LMO <http://luci.subsignal.org/trac/wiki/Documentation/LMO>`_).

Использование в шаблонах
========================
В шаблонах достаточно использовать таги *<%: something %>*, где
*something* это переводимая строка.

Использование в контроллерах
============================
* В самом контроллере вне всех методов необходимо подгрузить
  соответствующую библиотеку перевода для текущего выставленного языка::

    require( "luci.i18n" ).loadc( "astor2_san")

* Внутри методов желательно использовать удобную ссылку на функцию
  интернационализации LuCI::

    local i18n = luci.i18n.translate

* Любая строка, которую необходимо перевести, должна быть "обёрнута" в
  gettext-подобную функцию -- вышеназванную i18n::

    ...
    print( i18n("something for translation") )
    ...

Полезные ссылки
===============
* http://luci.subsignal.org/trac/wiki/Documentation/i18n
* http://luci.subsignal.org/trac/wiki/Documentation/LuCI-0.10
* http://www.gnu.org/software/gettext/manual/gettext.html
