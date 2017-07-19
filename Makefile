PACKAGE_VERSION = 1.0.1
TARGET = iphone:clang:latest:5.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TapForMore
TapForMore_FILES = DTActionSheet.m Tweak.xm
TapForMore_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TapForMore$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)