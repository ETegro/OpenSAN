.. _remotetesting-directories:

====================
Структура директорий
====================
::

  remotetesting
  ├── config
  ├── lib
  │   ├── functions.sh
  │   ├── functions-test.sh
  │   └── luaunit.lua
  ├── luas
  │   ├── clearing.lua
  │   ├── ...
  │   └── single_lvm.lua
  ├── perform.sh
  ├── results
  │   ├── ...
  │   └── 2011-06-12_14:28
  │       ├── 01single_target-dd
  │       │   └── dd_result
  │       └── 02single_target-iometer-fs
  │           └── fio_result
  └── tests
      ├── 01single_target-dd
      ├── ...
      └── 02single_target-iometer-fs

:config:
 Конфигурационный файл всей системы тестирования. В нём задаются вызовы
 команд используемых, а также адрес системы целевой
:perform.sh:
 Исполняемый файл запуска всего процесса тестирования
:lib:
 Различные файлы используемые всей системой тестирования
:lib/functions.sh:
 Различные команды bash доступные для использования всей системой
:lib/functions-test.sh:
 Различные команды bash доступные для использования самими тестами
:lib/luaunit.lua:
 Библиотека модульного тестирования Luaunit
:luas:
 Библиотека Lua скриптов. Сюда могут помещатся часто используемые Lua
 скрипты
:tests:
 Каждая поддиректория является отдельным тестом
