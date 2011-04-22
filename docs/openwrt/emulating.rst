.. _openwrt-emulating:

===================
Эмулирование образа
===================

Для создания виртуального сетевого интерфейса необходимо иметь
установленный пакет **uml-utilities**, после которого можно сразу же
выставить корректную конфигурацию IP-адресов::

  # tunctl -u username -t tap0
  # ip addr add 192.168.1.2/24 dev tap0
  # ip link set tap0 up

Для создания виртуальных жёстких дисков (например в 2 GiB) можно
использовать следующие комманды::

  % dd if=/dev/zero of=disk2.raw bs=1 count=1 seek=$(( 1024 * 1024 * 1024 * 2 ))
  % dd if=/dev/zero of=disk3.raw bs=1 count=1 seek=$(( 1024 * 1024 * 1024 * 2 ))
  % dd if=/dev/zero of=disk4.raw bs=1 count=1 seek=$(( 1024 * 1024 * 1024 * 2 ))

Для запуска самого qemu с привязкой к виртуальному сетевому адаптеру
и использованию виртуальных жёстких дисков::

  % qemu -m 64 -net nic -net tap,ifname=tap0,script=no,downscript=no -hda /path/to/image.raw -hdb disk2.raw -hdc disk3.raw -hdd disk4.raw
