LOCAL_PATH := $(call my-dir)
OPTEE_TEST_PATH := $(shell pwd)/$(LOCAL_PATH)

## include variants like TA_DEV_KIT_DIR
## and target of BUILD_OPTEE_OS
INCLUDE_FOR_BUILD_TA := false
include $(BUILD_OPTEE_MK)
INCLUDE_FOR_BUILD_TA :=

VERSION = $(shell git describe --always --dirty=-dev 2>/dev/null || echo Unknown)

# TA_DEV_KIT_DIR must be set to non-empty value to
# avoid the Android build scripts complaining about
# includes pointing outside the Android source tree.
# This var is expected to be set when OPTEE OS built.
# We set the default value to an invalid path.
TA_DEV_KIT_DIR ?= $(OPTEE_TEST_PATH)/export-ta_arm32

OPTEE_CLIENT_PATH ?= $(LOCAL_PATH)/../optee_client

include $(TA_DEV_KIT_DIR)/host_include/conf.mk

################################################################################
# Build TA                                                                  #
################################################################################
TEE_CROSS_COMPILE ?= $(shell pwd)/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
TEE_CROSS_COMPILE_HOST ?= $(shell pwd)/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
TEE_CROSS_COMPILE_TA ?= $(shell pwd)/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
TEE_CROSS_COMPILE_user_ta ?= $(shell pwd)/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-


.PHONY: TAs
TAs:
	$(MAKE) -C $(OPTEE_TEST_PATH) O=$(OPTEE_TEST_PATH) TA_DEV_KIT_DIR=$(TA_DEV_KIT_DIR) clean
	$(MAKE) -C $(OPTEE_TEST_PATH) CROSS_COMPILE=$(TEE_CROSS_COMPILE) \
	CROSS_COMPILE_HOST=$(TEE_CROSS_COMPILE_HOST) \
	CROSS_COMPILE_TA=$(TEE_CROSS_COMPILE_TA) \
	CROSS_COMPILE_user_ta=$(TEE_CROSS_COMPILE_user_ta) \
	TA_DEV_KIT_DIR=$(TA_DEV_KIT_DIR) \
	O=$(OPTEE_TEST_PATH)

%.ta: TAs
	@echo compiling ta ...

################################################################################
# Build testapp                                                                #
################################################################################
include $(CLEAR_VARS)
LOCAL_CFLAGS += -DANDROID_BUILD -DUSER_SPACE
LOCAL_CFLAGS += -Wall
LOCAL_LDFLAGS += -L$(OPTEE_CLIENT_PATH)/libs/armeabi/ -lteec
LOCAL_LDFLAGS += -llog

LOCAL_SRC_FILES += host/rkdemo/testapp_ca.c

LOCAL_C_INCLUDES := $(LOCAL_PATH)/ta/testapp/include \
		$(OPTEE_CLIENT_PATH)/public

LOCAL_SHARED_LIBRARIES := libteec

LOCAL_MODULE := testapp
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)

################################################################################
# Build testapp_storage                                                        #
################################################################################
include $(CLEAR_VARS)
LOCAL_CFLAGS += -DANDROID_BUILD -DUSER_SPACE
LOCAL_CFLAGS += -Wall
LOCAL_LDFLAGS += -L$(OPTEE_CLIENT_PATH)/libs/armeabi/ -lteec
LOCAL_LDFLAGS += -llog

LOCAL_SRC_FILES += host/rkdemo/testapp_storage_ca.c

LOCAL_C_INCLUDES := $(LOCAL_PATH)/ta/testapp_storage/include \
		$(OPTEE_CLIENT_PATH)/public

LOCAL_SHARED_LIBRARIES := libteec
LOCAL_MODULE := testapp_storage
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)

include $(LOCAL_PATH)/ta/Android.mk
