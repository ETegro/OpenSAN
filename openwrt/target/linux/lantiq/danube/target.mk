ARCH:=mips
SUBTARGET:=danube
BOARDNAME:=Danube
FEATURES:=squashfs jffs2 atm

DEFAULT_PACKAGES+=kmod-pppoa ppp-mod-pppoa linux-atm atm-tools br2684ctl kmod-ltq-dsl-danube ltq-dsl-app swconfig

define Target/Description
	Lantiq Danube/Twinpass
endef
