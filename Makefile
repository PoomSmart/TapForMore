GO_EASY_ON_ME = 1
DEBUG = 0
ARCHS = armv7 arm64
PACKAGE_VERSION = 1.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TapForMore
TapForMore_FILES = DTActionSheet.m Tweak.xm
TapForMore_FRAMEWORKS = UIKit
TapForMore_CFLAGS = -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TapForMore$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)