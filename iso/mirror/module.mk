# This module downloads centos installation images.
include $(SOURCE_DIR)/mirror/boot.mk

$(BUILD_DIR)/mirror/build.done: \
		$(BUILD_DIR)/mirror/ubuntu-netboot.done \
		$(BUILD_DIR)/mirror/boot.done
	$(ACTION.TOUCH)

