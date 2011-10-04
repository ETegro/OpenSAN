.. _remotetesting-lua-format:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

==================
Формат Lua-скрипта
==================
Lua-скрипты представляют из себя обыкновенный исходный код Lua в котором
выполняются luaunit unittest-ы. Отличие заключается в том, что в файле
вырезаны "заголовки" содержащие подключаемые библиотеки. Экономить на
подключении дополнительных библиотек не требуется, а код во всех
скриптах становится существенно меньше.

Изначальный Lua-скрипт
======================
::

  require( "luaunit" )
  require( "uci" )
  common = require( "astor2.common" )
  einarc = require( "astor2.einarc" )
  lvm = require( "astor2.lvm" )
  scst = require( "astor2.scst" )
  
  TestSomething = {}
  function TestSomething:test_something()
      -- do something
  end
  
  LuaUnit:run()

Lua-скрипт в требуемом формате
==============================
::

  TestSomething = {}
  function TestSomething:test_something()
      -- do something
  end

Вызовы тестов
=============
Система определяет производится ли вызов LuaUnit:run() в подготовленном
Lua-скрипте. Иногда простого вызова LuaUnit:run() не достаточно -- когда
важен порядок прохождения тестов. Если подобный вызов имеется, то
система не добавляет LuaUnit:run() по умолчанию.

Случайное имя
=============
Очень часта необходимость генерирования какого-нибудь псевдослучайного
имени для чего-либо. Все Lua-скрипты имеют возможность использовать
функцию *random_name()*.
