.. _trac-wiki_usage:
.. vim: syntax=rst
.. vim: textwidth=72
.. vim: spell spelllang=ru,en

==================
Использование wiki
==================
Чтобы иметь возможность централизовано хранить все данные wiki,
версионировать их, иметь возможность просмотра и создания в режиме
offline, решено не давать возможность online-редактирования страниц в
броузере.

Все страницы в wiki-разметке хранятся в репозитории, в директории
**/wiki**. Скрипт **insert_all.sh**, запускаемый на *opensan-trac*,
обновляет все страницы wiki, находящиеся в этой директории. Все страницы
должны иметь расширение файла **.wiki**. Название wiki-страницы
совпадает с названием файла **без** расширения.

Прикрепления
============
Если к странице необходимо прикрепить файл, то его необходимо положить в
директорию **/wiki/attachments/СТРАНИЦА**, где *СТРАНИЦА* это название
wiki-страницы. Все предыдущие версии файла этой страницы будут удалены! 
