.. _openwrt-building:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

================================
Использование сборочного скрипта
================================

.. contents::

Сборочный скрипт находится в **build/** директории репозитория. Для его
работы необходимо использовать конфигурационный файл **build.conf**.
Данный файл должен находится в одной директории с одним скриптом
(build.sh). Находящийся в репозитории скрипт имеет:

* настроенные репозитории aStor2 (на github.com-е)
* общая директория для хранения всех скачек (*/home/stargrave/dl* на
  build.etegro.local)

Конфигурационный файл OpenWRT находится в **build/.config** файле. При
сборке он будет символически связан с тем, что в сборочной директории
рабочей.

Запуск
======
Достаточно просто запустить сам скрипт::

  % /path/to/build.sh BRANCHNAME

В директории */path/to/* он создаст поддиректории:

:openwrt/trunk/:
 Собственно сама сборка происходит здесь
:output/YYYY-MM-DDTHH\:mm-BRANCHNAME:
 Вывод всего процесса сборки и полученные образы

*BRANCHNAME* -- название ветки которую необходимо checkout-ить из
репозитория и собирать. Если не указана, то по умолчанию подставляется
master.

Многопоточная сборка
====================
В **build.conf** количество потоков сборки для передачи в Makefile
задаётся параметром **JOBS=x**, где **x** это количество потоков.

Очистка промежуточных сборок
============================
Делать просто *make clean* или полную очистку (с пересборкой всех
кросс-компиляторов и уже собранных библиотек/программ) можно управляя
параметром **MRPROPER=[true|false]** в **build.conf**-е.
