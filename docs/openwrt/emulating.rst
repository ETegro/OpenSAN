.. _openwrt-emulating:

===================
Эмулирование образа
===================

::

  # tunctl -u username -t tap0
  # ip addr add 192.168.1.2/24 dev tap0
  # ip link set tap0 up
  % qemu -m 64 -net -nic -net tap,ifname=tap0,script=no,downscript=no /path/to/image.raw
