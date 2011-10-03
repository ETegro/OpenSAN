.. _github-ssh-keys:

================================
Установка SSH-ключей astor2-team
================================

SSH-ключи (astor2-id_rsa, astor2-id_rsa.pub) для
astor2-team учётной записи находятся в manufacturing
репозитории в **trunk/astor-keys** и на файл-сервере
**//fileserver.etegro.local/RnD/astor2**. Их необходимо скопировать
в **$HOME/.ssh** директорию и назначить соответствующие права доступа::

  chmod 600 $HOME/.ssh/astor2-id_rsa
  chmod 444 $HOME/.ssh/astor2-id_rsa.pub

Далее необходимо настроить хост github-astor2 который будет
принудительно использовать данные ключи при доступе на github.com
проекта astor2::

  Host github-astor2
  HostName github.com
  User git
  IdentityFile /home/stargrave/.ssh/astor2-id_rsa.pub
