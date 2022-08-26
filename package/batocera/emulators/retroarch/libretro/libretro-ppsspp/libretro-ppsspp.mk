################################################################################
#
# libretro-ppsspp
#
################################################################################

LIBRETRO_PPSSPP_VERSION = v1.13.1
LIBRETRO_PPSSPP_SITE = https://github.com/hrydgard/ppsspp.git
LIBRETRO_PPSSPP_SITE_METHOD=git
LIBRETRO_PPSSPP_GIT_SUBMODULES=YES
LIBRETRO_PPSSPP_LICENSE = GPLv2

LIBRETRO_PPSSPP_CONF_OPTS = \
	-DUSE_FFMPEG=ON -DUSE_SYSTEM_FFMPEG=OFF -DUSING_FBDEV=OFF -DUSE_WAYLAND_WSI=OFF \
	-DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Linux -DUSE_DISCORD=OFF \
	-DBUILD_SHARED_LIBS=OFF -DANDROID=OFF -DWIN32=OFF -DAPPLE=OFF \
	-DUNITTEST=OFF -DSIMULATOR=OFF -DLIBRETRO=ON

LIBRETRO_PPSSPP_TARGET_CFLAGS = $(TARGET_CFLAGS)

# enable vulkan if we are building with it
ifeq ($(BR2_PACKAGE_VULKAN_HEADERS)$(BR2_PACKAGE_VULKAN_LOADER),yy)
	LIBRETRO_PPSSPP_CONF_OPTS += -DVULKAN=ON
else
	LIBRETRO_PPSSPP_CONF_OPTS += -DVULKAN=OFF
endif

# enable x11/vulkan interface only if xorg
ifeq ($(BR2_PACKAGE_XORG7),y)
	LIBRETRO_PPSSPP_CONF_OPTS += -DUSING_X11_VULKAN=ON
else
	LIBRETRO_PPSSPP_CONF_OPTS += -DUSING_X11_VULKAN=OFF
	LIBRETRO_PPSSPP_TARGET_CFLAGS += -DEGL_NO_X11=1 -DMESA_EGL_NO_X11_HEADERS=1
endif

# arm
ifeq ($(BR2_arm),y)
    LIBRETRO_PPSSPP_CONF_OPTS += -DARM=ON
    LIBRETRO_PPSSPP_CONF_OPTS += -DARMV7=ON
	LIBRETRO_PPSSPP_CONF_OPTS += -DUSING_GLES2=ON
    LIBRETRO_PPSSPP_CONF_OPTS += -DUSING_EGL=ON
endif

ifeq ($(BR2_aarch64),y)
    LIBRETRO_PPSSPP_CONF_OPTS += -DARM=ON
	LIBRETRO_PPSSPP_CONF_OPTS += -DARM64=ON
	LIBRETRO_PPSSPP_CONF_OPTS += -DUSING_GLES2=ON
    LIBRETRO_PPSSPP_CONF_OPTS += -DUSING_EGL=ON
endif

# x86
ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_X86),y)
	LIBRETRO_PPSSPP_CONF_OPTS += -DX86=ON
endif

# x86_64
ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_X86_64_ANY),y)
	LIBRETRO_PPSSPP_CONF_OPTS += -DX86_64=ON
endif

# rockchip
ifeq ($(BR2_PACKAGE_BATOCERA_TARGET_ROCKCHIP_ANY),y)
    # In order to support the custom resolution patch, permissive compile is needed
    LIBRETRO_PPSSPP_TARGET_CFLAGS += -fpermissive
endif

ifeq ($(BR2_PACKAGE_HAS_LIBMALI),y)
    LIBRETRO_PPSSPP_CONF_OPTS += -DCMAKE_EXE_LINKER_FLAGS=-lmali -DCMAKE_SHARED_LINKER_FLAGS=-lmali
endif

LIBRETRO_PPSSPP_CONF_OPTS += -DCMAKE_C_FLAGS="$(LIBRETRO_PPSSPP_TARGET_CFLAGS)" -DCMAKE_CXX_FLAGS="$(LIBRETRO_PPSSPP_TARGET_CFLAGS)"

define LIBRETRO_PPSSPP_UPDATE_INCLUDES
	sed -i 's/unknown/"$(shell echo $(LIBRETRO_PPSSPP_VERSION) | cut -c 1-7)"/g' $(@D)/git-version.cmake
	sed -i "s+/opt/vc+$(STAGING_DIR)/usr+g" $(@D)/CMakeLists.txt
endef

LIBRETRO_PPSSPP_PRE_CONFIGURE_HOOKS += LIBRETRO_PPSSPP_UPDATE_INCLUDES

define LIBRETRO_PPSSPP_INSTALL_TARGET_CMDS
    $(INSTALL) -D $(@D)/lib/ppsspp_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/ppsspp_libretro.so

    # Required for game menus
    mkdir -p $(TARGET_DIR)/usr/share/ppsspp
	cp -R $(@D)/assets $(TARGET_DIR)/usr/share/ppsspp/PPSSPP
endef

$(eval $(cmake-package))
