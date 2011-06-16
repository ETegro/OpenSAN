.. _overview:

==================
Technical overview
==================
OpenSAN is based on several other free software projects:

:OpenWRT_:
 with own modified version of Linux is used as a base providing all
 necessary libraries, building framework and utilities to create
 lightweight, highly customized, easily upgradable environment for the
 following subsystems

:LuCI_:
 is used as MVC-framework for the overall Web-interface configuration
 management

:Einarc_:
 with software module enabled -- all configuration related to physical
 and logical drives management is performed through it

:LVM2_:
 for logical volumes with snapshots management

:SCST_:
 framework for creating iSCSI targets

:jQuery_:
 is used to make different pretty outlooking interface interactions

All interaction with Einarc, LVM2 and SCST subsystems is going through
the self-written API (*astor2.* libraries) on Lua programming
language.

.. _OpenWRT: http://www.openwrt.org/
.. _LuCI: http://luci.subsignal.org/
.. _Einarc: http://www.inquisitor.ru/doc/einarc/
.. _LVM2: http://sourceware.org/lvm2/
.. _SCST: http://scst.sourceforge.net/index.html
.. _jQuery: http://jquery.com/
