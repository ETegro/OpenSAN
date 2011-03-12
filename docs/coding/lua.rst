.. _coding-lua:

===
Lua
===

Аргументы функции **ОБЯЗАТЕЛЬНО** должны разделятся точками **с**
пробелами после::

  myfunc(foo,bar,baz)     <-- ПЛОХО
  myfunc(foo, bar, baz)   <-- ХОРОШО
  myfunc( foo, bar, baz ) <-- ЕЩЁ ЛУЧШЕ
  myfunc( foo,
          bar,
          baz )           <-- ДЛИННЫЕ АРГУМЕНТЫ ЕСЛИ
