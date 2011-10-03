.. _coding-luadoc:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

=================
Применение LuaDoc
=================

Все функции **ЖЕЛАТЕЛЬНО** снабжать удобочеловекочитаемыми комментариями
о том какие аргументы в каком формате требуются и что возвращается
функцией.

**ЖЕЛАТЕЛЬНО** использовать LuaDoc_ комментарии хотя бы в таком варианте:

* Описание функции находится в комментариях перед самой функцией
* Начало описания начинается с "--- " после которого следует короткое
  описание для человека в одну строчку
* Далее может идти описание функции свободным текстом
* Если имеются аргументы, то на отдельной строчке комментария начать его
  описание с "@param " после которого следует название аргумента, а
  после его человекочитаемое описание
* Если у функции имеется вывод, то на следующей строчке комментария
  начать его описание с "@return" после которого человекочитаемое
  описание

То есть, например::

  --- Call external command
  -- Lua's built-in methods are capable either only about getting
  -- return code from some external program, or only about getting it's
  -- stdout. This function can get all of them at once.
  -- @param cmdline "mdadm --examine /dev/sda"
  -- @return { return_code = 0, stderr = { "line1", "line2" }, stdout = { "line1", "line2" } }
  function system( cmdline )
  [...]
  end

.. _LuaDoc: http://luadoc.luaforge.net/
