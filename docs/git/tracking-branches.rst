.. _git-tracking-branches:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

================
Связывание веток
================

Для связывания (tracking) локальной и удалённой (remote) ветки, чтобы
*git status* показывали “расхождение” в коммитах между ними (кто кого
впереди и насколько), необходимо в конфигурационном файле
(*.git/config*) добавить следующую запись::

  [branch "ЛОКАЛЬНАЯ_ВЕТКА"]
    remote = origin
    merge = refs/heads/УДАЛЁННАЯ_ВЕТКА

