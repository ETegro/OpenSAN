.. _luci-local_environment:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

===================================
Настройка локального окружения LuCI
===================================

.. contents::

Установка необходимого ПО
=========================

* GCC
* pkg-config
* Flex
* Bison
* GNU Make
* wget
* Lua 5.1.x + development headers
* OpenSSL development headers
* iwlib development headers

Для Debian GNU/Linux 6.0 Squeeze
--------------------------------

::

  apt-get install build-essential \
                  pkg-config \
                  flex \
                  bison \
                  wget \
                  lua5.1 \
                  lua5.1-dev \
                  libssl-dev \
                  libiw-dev

Получение исходного кода LuCI
=============================

Исходный код LuCI можно взять из SVN::

  svn co http://svn.luci.subsignal.org/luci/tags/0.8.8 luci-0.8.8
  svn co http://svn.luci.subsignal.org/luci/trunk

Запуск LuCI
===========

::

  make runhttpd

Это команда подготавливает и собирает исходный код LuCI и зависимости и после
запускает LuCI вебсервер на http://localhost:8080/luci.

Дополнительные команды
----------------------

Команда **make run** считается устаревшей и не используется.

Для запуска LuCI WebUI, используя LuCIttpd::

  make runhttpd

Для запуска LuCI WebUI, используя Boa/Webuci::

  make runboa

Для запуска оболочки в среде LuCI::

  make runshell

Для запуска Lua CLI в среде LuCI::

  make runlua
