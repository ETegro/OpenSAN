/*
 *  Atheros PB92 board support
 *
 *  Copyright (C) 2010 Felix Fietkau <nbd@openwrt.org>
 *  Copyright (C) 2008-2009 Gabor Juhos <juhosg@openwrt.org>
 *  Copyright (C) 2008 Imre Kaloz <kaloz@openwrt.org>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/mtd/mtd.h>
#include <linux/mtd/partitions.h>
#include <asm/mach-ar71xx/ar71xx.h>

#include "machtype.h"
#include "devices.h"
#include "dev-m25p80.h"
#include "dev-gpio-buttons.h"
#include "dev-pb9x-pci.h"
#include "dev-usb.h"

#ifdef CONFIG_MTD_PARTITIONS
static struct mtd_partition pb92_partitions[] = {
	{
		.name		= "u-boot",
		.offset		= 0,
		.size		= 0x040000,
		.mask_flags	= MTD_WRITEABLE,
	}, {
		.name		= "u-boot-env",
		.offset		= 0x040000,
		.size		= 0x010000,
	}, {
		.name		= "rootfs",
		.offset		= 0x050000,
		.size		= 0x2b0000,
	}, {
		.name		= "uImage",
		.offset		= 0x300000,
		.size		= 0x0e0000,
	}, {
		.name		= "ART",
		.offset		= 0x3e0000,
		.size		= 0x020000,
		.mask_flags	= MTD_WRITEABLE,
	}
};
#endif /* CONFIG_MTD_PARTITIONS */

static struct flash_platform_data pb92_flash_data = {
#ifdef CONFIG_MTD_PARTITIONS
	.parts		= pb92_partitions,
	.nr_parts	= ARRAY_SIZE(pb92_partitions),
#endif
};


#define PB92_BUTTONS_POLL_INTERVAL	20

#define PB92_GPIO_BTN_SW4	8
#define PB92_GPIO_BTN_SW5	3

static struct gpio_button pb92_gpio_buttons[] __initdata = {
	{
		.desc		= "sw4",
		.type		= EV_KEY,
		.code		= BTN_0,
		.threshold	= 3,
		.gpio		= PB92_GPIO_BTN_SW4,
		.active_low	= 1,
	}, {
		.desc		= "sw5",
		.type		= EV_KEY,
		.code		= BTN_1,
		.threshold	= 3,
		.gpio		= PB92_GPIO_BTN_SW5,
		.active_low	= 1,
	}
};

static void __init pb92_init(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1fff0000);

	ar71xx_add_device_m25p80(&pb92_flash_data);

	ar71xx_add_device_mdio(~0);
	ar71xx_init_mac(ar71xx_eth0_data.mac_addr, mac, 0);
	ar71xx_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_RMII;
	ar71xx_eth0_data.speed = SPEED_1000;
	ar71xx_eth0_data.duplex = DUPLEX_FULL;

	ar71xx_init_mac(ar71xx_eth1_data.mac_addr, mac, 1);
	ar71xx_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_RMII;
	ar71xx_eth1_data.speed = SPEED_1000;
	ar71xx_eth1_data.duplex = DUPLEX_FULL;

	ar71xx_add_device_eth(0);
	ar71xx_add_device_eth(1);

	ar71xx_add_device_gpio_buttons(-1, PB92_BUTTONS_POLL_INTERVAL,
					ARRAY_SIZE(pb92_gpio_buttons),
					pb92_gpio_buttons);

	pb9x_pci_init();
}

MIPS_MACHINE(AR71XX_MACH_PB92, "PB92", "Atheros PB92", pb92_init);
