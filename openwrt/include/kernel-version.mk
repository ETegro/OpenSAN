# Use the default kernel version if the Makefile doesn't override it

LINUX_RELEASE?=1

ifeq ($(LINUX_VERSION),2.6.30.10)
  LINUX_KERNEL_MD5SUM:=eb6be465f914275967a5602cb33662f5
endif
ifeq ($(LINUX_VERSION),2.6.31.14)
  LINUX_KERNEL_MD5SUM:=3e7feb224197d8e174a90dd3759979fd
endif
ifeq ($(LINUX_VERSION),2.6.32.33)
  LINUX_KERNEL_MD5SUM:=2b4e5ed210534d9b4f5a563089dfcc80
endif
# Special 2.6.32.35 version is Ubuntu's 2.6.35.14 one:
# wget ftp://mirror.yandex.ru/ubuntu/pool/main/l/linux/linux-source-2.6.35_2.6.35-32.68_all.deb
# dpkg --extract linux-source-2.6.35_2.6.35-32.68_all.deb linux-source
# cd linux-source/usr/src/linux-source-2.6.35/
# bunzip2 -c < linux-source-2.6.35.tar.bz2 | pax -r
# mv linux-source-2.6.35 linux-2.6.32.35
# find linux-2.6.32.35 | pax -wd | bzip2 -9c > linux-2.6.32.35.tar.bz2
ifeq ($(LINUX_VERSION),2.6.32.35)
  LINUX_KERNEL_MD5SUM:=474d20070e2e787d383c71b0315bb410
endif
ifeq ($(LINUX_VERSION),2.6.32.50)
  LINUX_KERNEL_MD5SUM:=b8968ef9605467332a45739c392956d1
endif
ifeq ($(LINUX_VERSION),2.6.32.59)
  LINUX_KERNEL_MD5SUM:=69c68c4a8eb0f04b051a7dbcff16f6d0
endif
ifeq ($(LINUX_VERSION),2.6.34.8)
  LINUX_KERNEL_MD5SUM:=6dedac89df1af57b08981fcc6ad387db
endif
ifeq ($(LINUX_VERSION),2.6.35.11)
  LINUX_KERNEL_MD5SUM:=4c9ee33801f5ad0f4d5e615fac66d535
endif
ifeq ($(LINUX_VERSION),2.6.36.4)
  LINUX_KERNEL_MD5SUM:=c05dd941d0e249695e9f72568888e1bf
endif
ifeq ($(LINUX_VERSION),2.6.37.6)
  LINUX_KERNEL_MD5SUM:=05970afdce8ec4323a10dcd42bc4fb0c
endif
ifeq ($(LINUX_VERSION),2.6.38.8)
  LINUX_KERNEL_MD5SUM:=d27b85795c6bc56b5a38d7d31bf1d724
endif
ifeq ($(LINUX_VERSION),2.6.39.4)
  LINUX_KERNEL_MD5SUM:=a17c748c2070168f1e784e9605ca043d
endif
ifeq ($(LINUX_VERSION),3.0.3)
  LINUX_KERNEL_MD5SUM:=6a8af5f6733b3db970197e65b3db712c
endif
ifeq ($(LINUX_VERSION),3.1)
  LINUX_KERNEL_MD5SUM:=8d43453f8159b2332ad410b19d86a931
endif

# disable the md5sum check for unknown kernel versions
LINUX_KERNEL_MD5SUM?=x

split_version=$(subst ., ,$(1))
merge_version=$(subst $(space),.,$(1))
KERNEL_BASE=$(firstword $(subst -, ,$(LINUX_VERSION)))
KERNEL=$(call merge_version,$(wordlist 1,2,$(call split_version,$(KERNEL_BASE))))
ifeq ($(firstword $(call split_version,$(KERNEL_BASE))),2)
  KERNEL_PATCHVER=$(call merge_version,$(wordlist 1,3,$(call split_version,$(KERNEL_BASE))))
else
  KERNEL_PATCHVER=$(KERNEL)
endif

