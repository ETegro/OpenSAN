.. _coding-lua:

===
Lua
===

* Аргументы функции **ОБЯЗАТЕЛЬНО** должны разделятся точками **с**
  пробелами после::

    myfunc(foo,bar,baz)     <-- ПЛОХО
    myfunc(foo, bar, baz)   <-- ХОРОШО
    myfunc( foo, bar, baz ) <-- ЕЩЁ ЛУЧШЕ
    myfunc( foo,
            bar,
            baz )           <-- ДЛИННЫЕ АРГУМЕНТЫ ЕСЛИ

* **ЖЕЛАТЕЛЬНО** использовать "псевдо-методы" для хэшей если это
  возможно и если хэш не используется в качестве массива::

    foo = { "erste", "zweite", "dritte" }
    print( foo[1], foo[2] )

    foobar = { foo = { bar = "baz" } }
    for k, v in pairs( foobar ) do
      print( foobar[ k ].bar )
    end

