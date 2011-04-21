.. _scst-uci:

===================
UCI SCST подсистемы
===================

Вариант схемы UCI для SCST подсистемы::

  config "access-pattern" "erste_pattern"
    option "name" "foobar pattern name"
    option "targetdriver" "iscsi"
    option "lun" "2"
    option "enabled" "1"
    option "readonly" "0"
    option "filename" "/dev/vg1303136641/volname"

Также имеется ряд тезисов:

* LogicalVolume может быть "отдан" только по одному транспорту
* LogicalVolume может быть "отдан" по нескольким SCSTAccessPattern-ам
* SCSTAccessPattern не может "ссылаться" на несколько блочных устройств
