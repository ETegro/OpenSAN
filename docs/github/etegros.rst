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

Внутри сети ETegro из-за использования NAT-а это работать не будет и
необходимо использовать внутрисетевые настройки доступа::

  git remote add etegro-build-local ssh://build@build.etegro.local/~build/astor2.git
