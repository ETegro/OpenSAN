/*
 * Ralink machine types
 *
 * Copyright (C) 2010 Joonas Lahtinen <joonas.lahtinen@gmail.com>
 * Copyright (C) 2009 Gabor Juhos <juhosg@openwrt.org>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published
 * by the Free Software Foundation.
 */

#include <asm/mips_machine.h>

enum ramips_mach_type {
	RAMIPS_MACH_GENERIC,
	/* RT2880 based machines */
	RAMIPS_MACH_RT_N15,		/* Asus RT-N15 */
	RAMIPS_MACH_WZR_AGL300NH,	/* Buffalo WZR-AGL300NH */

	/* RT3050 based machines */
	RAMIPS_MACH_DIR_300_REVB,	/* D-Link DIR-300 rev B */

	/* RT3052 based machines */
	RAMIPS_MACH_F5D8235_V2,         /* Belkin F5D8235 v2 */
	RAMIPS_MACH_PWH2004,		/* Prolink 2004H / Abocom 5205 */
	RAMIPS_MACH_WCR150GN,		/* Sparklan WCR-150GN */
	RAMIPS_MACH_V22RW_2X2,		/* Ralink AP-RT3052-V22RW-2X2 */
	RAMIPS_MACH_WHR_G300N,		/* Buffalo WHR-G300N */
	RAMIPS_MACH_FONERA20N,		/* La Fonera 2.0N */
};
