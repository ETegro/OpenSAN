.. _luci-unittesting:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

=======================
Запуск модульных тестов
=======================

Так как у нас все модули LuCI приложения сильно зависят от различных
сторонних библиотек, то необходимо немного повозится с тем, чтобы
запустить модульные тесты.

Проще всего сделать символические ссылки на библиотеки и пустышки
библиотек::

  % pwd
  ~/work/astor2/feeds/luci/applications/luci-astor2-san/luasrc/controller
  % mkdir astor2
  % ln -s ~/work/astor2/feeds/astor2/astor2-lua-common/files/astor2/common.lua astor2/
  % ln -s ~/work/astor2/feeds/astor2/astor2-lua-einarc/files/astor2/einarc.lua astor2/
  % ln -s ~/work/astor2/feeds/astor2/astor2-lua-lvm/files/astor2/lvm.lua astor2/
  % ln -s ~/work/astor2/feeds/astor2/astor2-lua-scst/files/astor2/scst.lua astor2/
  % echo 'module("uci")' > uci.lua

Запуск производится просто::

  % lua tests/gcd.lua
  % lua tests/mibtotib.lua
  % lua tests/matrix.lua
