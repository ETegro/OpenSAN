/*
 *  TP-LINK TL-MR3220/3420 board support
 *
 *  Copyright (C) 2010 Gabor Juhos <juhosg@openwrt.org>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/gpio.h>
#include <linux/mtd/mtd.h>
#include <linux/mtd/partitions.h>

#include <asm/mach-ar71xx/ar71xx.h>

#include "machtype.h"
#include "devices.h"
#include "dev-m25p80.h"
#include "dev-ap91-pci.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-usb.h"

#define TL_MR3X20_GPIO_LED_QSS		0
#define TL_MR3X20_GPIO_LED_SYSTEM	1
#define TL_MR3X20_GPIO_LED_3G		8

#define TL_MR3X20_GPIO_BTN_RESET	11
#define TL_MR3X20_GPIO_BTN_QSS		12

#define TL_MR3X20_GPIO_USB_POWER	6

#define TL_MR3X20_BUTTONS_POLL_INTERVAL	20

#ifdef CONFIG_MTD_PARTITIONS
static struct mtd_partition tl_mr3x20_partitions[] = {
	{
		.name		= "u-boot",
		.offset		= 0,
		.size		= 0x020000,
		.mask_flags	= MTD_WRITEABLE,
	}, {
		.name		= "kernel",
		.offset		= 0x020000,
		.size		= 0x140000,
	}, {
		.name		= "rootfs",
		.offset		= 0x160000,
		.size		= 0x290000,
	}, {
		.name		= "art",
		.offset		= 0x3f0000,
		.size		= 0x010000,
		.mask_flags	= MTD_WRITEABLE,
	}, {
		.name		= "firmware",
		.offset		= 0x020000,
		.size		= 0x3d0000,
	}
};
#define tl_mr3x20_num_partitions	ARRAY_SIZE(tl_mr3x20_partitions)
#else
#define tl_mr3x20_partitions		NULL
#define tl_mr3x20_num_partitions	0
#endif /* CONFIG_MTD_PARTITIONS */

static struct flash_platform_data tl_mr3x20_flash_data = {
	.parts		= tl_mr3x20_partitions,
	.nr_parts	= tl_mr3x20_num_partitions,
};

static struct gpio_led tl_mr3x20_leds_gpio[] __initdata = {
	{
		.name		= "tl-mr3x20:green:system",
		.gpio		= TL_MR3X20_GPIO_LED_SYSTEM,
		.active_low	= 1,
	}, {
		.name		= "tl-mr3x20:green:qss",
		.gpio		= TL_MR3X20_GPIO_LED_QSS,
		.active_low	= 1,
	}, {
		.name		= "tl-mr3x20:green:3g",
		.gpio		= TL_MR3X20_GPIO_LED_3G,
		.active_low	= 1,
	}
};

static struct gpio_button tl_mr3x20_gpio_buttons[] __initdata = {
	{
		.desc		= "reset",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.threshold	= 3,
		.gpio		= TL_MR3X20_GPIO_BTN_RESET,
		.active_low	= 1,
	}, {
		.desc		= "qss",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.threshold	= 3,
		.gpio		= TL_MR3X20_GPIO_BTN_QSS,
		.active_low	= 1,
	}
};

static void __init tl_mr3x20_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	/* enable power for the USB port */
	gpio_request(TL_MR3X20_GPIO_USB_POWER, "USB power");
	gpio_direction_output(TL_MR3X20_GPIO_USB_POWER, 1);

	ar71xx_add_device_m25p80(&tl_mr3x20_flash_data);

	ar71xx_add_device_leds_gpio(-1, ARRAY_SIZE(tl_mr3x20_leds_gpio),
					tl_mr3x20_leds_gpio);

	ar71xx_add_device_gpio_buttons(-1, TL_MR3X20_BUTTONS_POLL_INTERVAL,
					ARRAY_SIZE(tl_mr3x20_gpio_buttons),
					tl_mr3x20_gpio_buttons);

	ar71xx_eth1_data.has_ar7240_switch = 1;
	ar71xx_init_mac(ar71xx_eth0_data.mac_addr, mac, 0);
	ar71xx_init_mac(ar71xx_eth1_data.mac_addr, mac, 1);

	/* WAN port */
	ar71xx_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_RMII;
	ar71xx_eth0_data.speed = SPEED_100;
	ar71xx_eth0_data.duplex = DUPLEX_FULL;

	/* LAN ports */
	ar71xx_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_RMII;
	ar71xx_eth1_data.speed = SPEED_1000;
	ar71xx_eth1_data.duplex = DUPLEX_FULL;

	ar71xx_add_device_mdio(0x0);
	ar71xx_add_device_eth(1);
	ar71xx_add_device_eth(0);

	ar71xx_add_device_usb();

	ap91_pci_init(ee, mac);
}

static void __init tl_mr3220_setup(void)
{
	tl_mr3x20_setup();
	ap91_pci_setup_wmac_led_pin(1);
}

MIPS_MACHINE(AR71XX_MACH_TL_MR3220, "TL-MR3220", "TP-LINK TL-MR3220",
	     tl_mr3220_setup);

static void __init tl_mr3420_setup(void)
{
	tl_mr3x20_setup();
	ap91_pci_setup_wmac_led_pin(0);
}

MIPS_MACHINE(AR71XX_MACH_TL_MR3420, "TL-MR3420", "TP-LINK TL-MR3420",
	     tl_mr3420_setup);
