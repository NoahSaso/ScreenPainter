GO_EASY_ON_ME = 1

export ARCHS = armv7 arm64 armv7s

include theos/makefiles/common.mk

TWEAK_NAME = ScreenPainter
ScreenPainter_FILES = Tweak.xm Drag.xm DragTextView.mm iOSVersion/iOSVersion.m
ScreenPainter_FRAMEWORKS = UIKit CoreGraphics
ScreenPainter_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += screenpainter
SUBPROJECTS += screenpaintera
include $(THEOS_MAKE_PATH)/aggregate.mk
