include theos/makefiles/common.mk

BUNDLE_NAME = ScreenPainter
ScreenPainter_FILES = ScreenPainter.mm
ScreenPainter_INSTALL_PATH = /Library/PreferenceBundles
ScreenPainter_FRAMEWORKS = UIKit
ScreenPainter_PRIVATE_FRAMEWORKS = Preferences CoreGraphics

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ScreenPainter.plist$(ECHO_END)
