################################################################################
#
# vpp
#
# build reference example is taken from here:
# https://lists.fd.io/pipermail/vpp-dev/2017-January/003646.html
# http://dpdk.org/ml/archives/dev/2014-September/005202.html
#
################################################################################

VPP_VERSION = 17.0.4-ioam-anycast
VPP_SITE = https://github.com/vpp-dev/vpp/archive
VPP_SOURCE = $(VPP_VERSION).tar.gz
VPP_LICENSE = Apache License 2.0
VPP_LICENSE_FILES = LICENSE
VPP_INSTALL_STAGING = Yes
VPP_CONF_OPTS = -DVMCS_INSTALL_PREFIX=/usr \
	-DCMAKE_C_FLAGS="$(TARGET_CFLAGS) \
		-DVCFILED_LOCKFILE=\\\"/var/run/vcfiled.pid\\\""

#HOST_VPP_DEPENDENCIES = host-uclibc-ng
ifeq ($(BR2_TOOLCHAIN_BUILDROOT_GLIBC),y)
HOST_VPP_DEPENDENCIES = host-glibc
endif #BR2_TOOLCHAIN_BUILDROOT_GLIBC
ifeq ($(BR2_TOOLCHAIN_BUILDROOT_MUSL),y)
HOST_VPP_DEPENDENCIES = host-musl
endif #BR2_TOOLCHAIN_BUILDROOT_MUSL

VPP_DEPENDENCIES = openssl

#       BR ARCH         vpp
#       -------         ----
#       arm             arm
#       arm64           arm64
#       armeb           not supported
#       bfin            not supported
#       i486            x86_x32
#       i586            x86_x32
#       i686            i686
#       x86_64          x86_64
#       m68k            not supported
#       microblaze      not supported
#       mips            not supported
#       mipsel          not supported
#       mips64          not supported
#       mips64el        not supported
#       powerpc         not supported
#       powerpc64       ppc_64
#       powerpc64le     not supported
#       sh2a            not supported
#       sh4             not supported
#       sh4eb           not supported
#       sh4a            not supported
#       sh4aeb          not supported
#       sh64            not supported
#       sparc           not supported

HOST_OS = $(shell package/vpp/core.sh)
NR2_ARCH := $(patsubst "%",%,$(BR2_ARCH))

#quote-full
#$(BR2_ARCH)
#quote-less
#$(ARCH)

# --- ARCH remapping block

ifeq ($(BR2_ARCH),"arm")
HOST_VPP_ARCH = arm
HOST_DPDK_MACHINE = armv7a
endif
ifeq ($(BR2_ARCH),"aarch64")
HOST_VPP_ARCH = arm64
HOST_DPDK_MACHINE = xgene1
endif
ifeq ($(BR2_ARCH),"arm64")
HOST_VPP_ARCH = arm64
HOST_DPDK_MACHINE = armv8a
endif
ifeq ($(BR2_ARCH),"i486")
HOST_VPP_ARCH = x86_x32
HOST_DPDK_MACHINE = native
endif
ifeq ($(BR2_ARCH),"i586")
HOST_VPP_ARCH = x86_x32
HOST_DPDK_MACHINE = native
endif
ifeq ($(BR2_ARCH),"i686")
HOST_VPP_ARCH = i686
HOST_DPDK_MACHINE = native
endif
ifeq ($(BR2_ARCH),"x86_64")
HOST_VPP_ARCH = x86_64
HOST_DPDK_MACHINE = native
endif
ifeq ($(BR2_ARCH),"powerpc64")
HOST_VPP_ARCH = ppc_64
HOST_DPDK_MACHINE = power8
endif

HOST_DPDK_CONFIG = $(HOST_VPP_ARCH)-$(HOST_DPDK_MACHINE)-$(HOST_OS)app-gcc

# variables expected inside dpdk or vpp build system
#PLATFORM="$(NR2_ARCH)"
#$(BR2_ARCH)_os="$(HOST_OS)"
#$(BR2_ARCH)_arch="$(NR2_ARCH)"
#$(BR2_ARCH)_target="$(NR2_ARCH)-buildroot"
#CROSS="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-"
#CONFIG_RTE_TOOLCHAIN="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-gcc"
#TARGET_GCC="$(TARGET_CC)"
#DPDK_TARGET="$(HOST_DPDK_CONFIG)"
#DPDK_MACHINE="$(HOST_DPDK_MACHINE)"
#DPDK_CC="gcc" - already default (altered inside 0009.patch
#DPDK_TUNE="$(HOST_DPDK_MACHINE)"
#EXTRA_CFLAGS="-msse4.2" - will get's enabled by DPDK_DESPERATE_SSSE3=y
#vpp_uses_external_dpdk="yes"
#already "installed" DPDK headers and libraries
#DPDK_INCLUDE="$(TARGET)/include/dpdk"
#DPDK_LIB="$(TARGET)/lib"
#cross_compiling="yes"
#VPPAPIGEN="output/build/vpp-17.0.4-ioam-anycast/build-root/build-tool-native/tools/vppapigen" 

# --- build host part
define HOST_VPP_BUILD_CMDS
	@echo "HOST tools (vppapigen, etc.) BUILD STAGE"

# --- vpp API generation dependency HOST tools only compilation (no need for cross-build configuration)
	$(TARGET_MAKE_ENV) TARGET_GCC="$(TARGET_CC)" CROSS="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-" PLATFORM="$(NR2_ARCH)" $(NR2_ARCH)_os="$(HOST_OS)" $(NR2_ARCH)_arch="$(NR2_ARCH)" $(MAKE) v=1 -C $(@D) bootstrap
endef

# --- configure part
ifneq ($(BR2_PACKAGE_VPP_DPDK),)
define VPP_CONFIGURE_CMDS
	@echo "CONFIGURE STAGE" 

# --- DPDK configuration for standalone build only
	$(TARGET_MAKE_ENV) DPDK_TUNE="$(HOST_DPDK_MACHINE)" DPDK_MACHINE="$(HOST_DPDK_MACHINE)" DPDK_TARGET="$(HOST_DPDK_CONFIG)" CROSS="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-" PLATFORM="$(NR2_ARCH)" $(NR2_ARCH)_os="$(HOST_OS)" $(NR2_ARCH)_arch="$(NR2_ARCH)" $(MAKE) v=1 -C $(@D)/dpdk config
endef
else
define VPP_CONFIGURE_CMDS
	@echo "CONFIGURE STAGE" 
	@echo "NOTHING to CONFIGURE"
endef
endif

# --- build part
ifneq ($(BR2_PACKAGE_VPP_DPDK),)
define VPP_BUILD_CMDS
	@echo "BUILD STAGE"

# --- DPDK compilation for standalone build only
	@echo "DPDK install"
	$(TARGET_MAKE_ENV) CROSS="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-" PLATFORM="$(NR2_ARCH)" $(NR2_ARCH)_os="$(HOST_OS)" $(NR2_ARCH)_arch="$(NR2_ARCH)" DPDK_TUNE="$(HOST_DPDK_MACHINE)" DPDK_TARGET="$(HOST_DPDK_CONFIG)" DPDK_MACHINE="$(HOST_DPDK_MACHINE)" $(MAKE) v=1 -C $(@D)/dpdk install

# --- external DPDK based VPP build process (expected DPDK already configured/compiled/installed with the path provided)
	@echo "VPP build"
	$(TARGET_MAKE_ENV) TARGET_GCC="$(TARGET_CC)" PLATFORM="$(NR2_ARCH)" $(NR2_ARCH)_os="$(HOST_OS)-gnu" $(NR2_ARCH)_arch="$(NR2_ARCH)-buildroot" \
		CROSS="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-" \
VPPAPIGEN="$(@D)/build-root/build-tool-native/tools/vppapigen" \
DPDK_INCLUDE="$(TARGET)/include/dpdk" \
DPDK_LIB="$(TARGET)/lib" \
DPDK_MACHINE="$(HOST_DPDK_MACHINE)" \
DPDK_TARGET="$(HOST_DPDK_CONFIG)" \
DPDK_TUNE="$(HOST_DPDK_MACHINE)" \
$(MAKE) v=1 -C $(@D) build 
endef
else
define VPP_BUILD_CMDS
	@echo "BUILD STAGE"

# --- all-in-one VPP build process (starting with DPDK download/patch/compilation, i.e. require cross-build configuration)
	@echo "VPP all-in-one build"
	$(TARGET_MAKE_ENV) TARGET_GCC="$(TARGET_CC)" PLATFORM="$(NR2_ARCH)" $(NR2_ARCH)_os="$(HOST_OS)-gnu" $(NR2_ARCH)_arch="$(NR2_ARCH)-buildroot" \
		CROSS="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-" \
CONFIG_RTE_TOOLCHAIN="$(NR2_ARCH)-buildroot-$(HOST_OS)-gnu-gcc" \
VPPAPIGEN="$(@D)/build-root/build-tool-native/tools/vppapigen" \
DPDK_TARGET="$(HOST_DPDK_CONFIG)" \
DPDK_TUNE="$(HOST_DPDK_MACHINE)" \
$(MAKE) v=1 -C $(@D) build 
endef
endif

# clear part
define VPP_CLEAN_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) V=1 wipe
endef

$(eval $(generic-package))
