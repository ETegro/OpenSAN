.. _github-cloning:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

================================================
Клонирование и настройка удалённого репозиториев 
================================================

Клонируйте репозиторий astor2::

  git clone git://github.com/astor2-team/astor2.git astor2

Измените автоматически прописанный удалённый репозиторий в
**.git/config** с целью использования конкретно astor2-team аккаунта::

  git remote set-url origin "git@github-astor2:astor2-team/astor2.git"

.. warning::

   Вместо сервера **github.com** был указан **github-astor2** который
   является хостом описанным в SSH конфигурации.
