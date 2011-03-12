.. _github-etegros:

====================
Репозиторий в ETegro
====================

Репозиторий находится на **build.etegro.local** компьютере
в домашней директории пользователя **build**. Доступ по SSH
протоколу возможен через проброшенный порт 2222 на сервере
clone.etegro.com. Авторизоваться под вышеназванным пользователем
можно используя **astor2-team** SSH-ключи.

Чтобы добавить данный репозиторий как *remote* необходимо выполнить
следующую команду (в директории проекта astor2)::

  git remote add etegro-build ssh://build@clone.etegro.com:2222/~build/astor2.git

.. note::

   Внутри сети ETegro из-за использования NAT-а это работать не будет и
   необходимо использовать внутрисетевые настройки доступа::
   
     git remote add etegro-build-local ssh://build@build.etegro.local/~build/astor2.git

Чтобы иметь возможность совершать push-и в оба репозитория сразу можно
добавить два URL используемых исключительно для push в описание *origin*
remote-а::

  git remote set-url --add --push origin git@github-astor2:astor2-team/astor2.git
  git remote set-url --add --push origin ssh://build@clone.etegro.com:2222/~build/astor2.git

.. note::

   Разность адресов внутри сети ETegro здесь также как и в
   вышеприведённой заметке присутствует.
