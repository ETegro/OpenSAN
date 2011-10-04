.. _git-signed-off:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

=============================
Добавление Signed-off-by поля
=============================

Чтобы сделать автоматическое добавление подписи Signed-off-by необходимо
в **.git/hooks** переименовать файл **prepare-commit-msg.sample** в
**prepare-commit-msg** и раскомментировать строки с *^SOB* и *^grep* в
конце.
