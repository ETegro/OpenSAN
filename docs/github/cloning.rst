.. _github-cloning:

================================================
Клонирование и настройка удалённого репозиториев 
================================================

Клонируйте репозиторий astor2::

  git clone git://github.com/astor2-team/astor2.git astor2

Измените автоматически прописанный удалённый репозиторий в
**.git/config** с целью использования конкретно astor2-team аккаунта::

  6,8d5
  < [remote "origin"]
  < 	fetch = +refs/heads/*:refs/remotes/origin/*
  < 	url = git://github.com/astor2-team/astor2.git
  11a9,11
  > [remote "origin"]
  > 	url = git@github-astor2:astor2-team/astor2.git
  > 	fetch = +refs/heads/*:refs/remotes/origin/*

.. warning::

   Вместо сервера **github.com** был указан **github-astor2** который
   является хостом описанным в SSH конфигурации.
