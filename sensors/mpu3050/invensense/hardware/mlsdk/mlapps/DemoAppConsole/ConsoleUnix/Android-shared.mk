EXEC = consoledmp$(SHARED_APP_SUFFIX)

MK_NAME = $(notdir $(CURDIR)/$(firstword $(MAKEFILE_LIST)))

CROSS = $(ANDROID_ROOT)/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-
COMP  = $(CROSS)gcc
LINK  = $(CROSS)gcc

OBJFOLDER=$(CURDIR)/obj

MLSDK_ROOT = $(CURDIR)/../../..
ML_COMMON_DIR = $(MLSDK_ROOT)/mlapps/common
MPL_DIR = $(MLSDK_ROOT)/mldmp
MLLITE_DIR = $(MLSDK_ROOT)/mllite
MLPLATFORM_DIR = $(MLSDK_ROOT)/platform

include $(MLSDK_ROOT)/Android-common.mk

CFLAGS += $(CMDLINE_CFLAGS)
CFLAGS += -Wall
#CFLAGS += -g
CFLAGS += -fpic 
CFLAGS += -D_REENTRANT -DLINUX -DANDROID
CFLAGS += -DSK_RELEASE
CFLAGS += -DUNICODE -D_UNICODE
CFLAGS += -DMPL_LOG_NDEBUG=1 -DNDEBUG -UDEBUG
CFLAGS += -mthumb-interwork 
CFLAGS += -fno-exceptions -ffunction-sections -funwind-tables 
CFLAGS += -fstack-protector -fmessage-length=0 -fno-short-enums
CFLAGS += -I$(MLPLATFORM_DIR)/include -I$(MLPLATFORM_DIR)/linux/kernel -I$(MLLITE_DIR) -I$(MPL_DIR) -I$(MLSDK_ROOT)/mlutils
CFLAGS += -I$(ML_COMMON_DIR) -I$(MLSDK_ROOT)/mltools/debugsupport

LLIBS = -lc -lm -lutils -lcutils -lgcc

PRE_LFLAGS := -Wl,-T,$(ANDROID_ROOT)/build/core/armelf.x
PRE_LFLAGS += \
    $(ANDROID_ROOT)/out/target/product/$(PRODUCT)/obj/lib/crtend_android.o \
    $(ANDROID_ROOT)/out/target/product/$(PRODUCT)/obj/lib/crtbegin_dynamic.o

LFLAGS += $(CMDLINE_LFLAGS)
LFLAGS += -rdynamic -nostdlib -fpic
LFLAGS += -Wl,--gc-sections -Wl,--no-whole-archive
LFLAGS += -Wl,-dynamic-linker,/system/bin/linker 
LFLAGS += $(ANDROID_LINK)

LRPATH := -Wl,-rpath,$(ANDROID_ROOT)/out/target/product/$(PRODUCT)/obj/lib:$(ANDROID_ROOT)/out/target/product/$(PRODUCT)/system/lib:$(MPL_DIR)/mpl/$(TARGET):$(MLLITE_DIR)/mpl/$(TARGET):$(MLPLATFORM_DIR)/linux:

VPATH += $(ML_COMMON_DIR) $(MLLITE_DIR)

####################################################################################################
## sources

ML_LIBS = \
	$(MPL_DIR)/mpl/$(TARGET)/$(LIB_PREFIX)$(MPL_LIB_NAME).$(SHARED_LIB_EXT) \
	$(MLLITE_DIR)/mpl/$(TARGET)/$(LIB_PREFIX)$(MLLITE_LIB_NAME).$(SHARED_LIB_EXT) \
	$(MLPLATFORM_DIR)/linux/$(LIB_PREFIX)$(MLPLATFORM_LIB_NAME).$(SHARED_LIB_EXT)

ML_SRCS = \
	consoledmp.c \
	$(ML_COMMON_DIR)/mlsetup.c \
	$(ML_COMMON_DIR)/helper.c \
	$(ML_COMMON_DIR)/gestureMenu.c \
	$(ML_COMMON_DIR)/mlerrorcode.c \
	$(MLLITE_DIR)/mlmath.c

ML_OBJS = $(addsuffix .o, $(ML_SRCS))
ML_OBJS_DST = $(addprefix $(OBJFOLDER)/,$(notdir $(ML_OBJS)))

####################################################################################################
## rules

.PHONY: all clean cleanall install

all: $(EXEC) $(MK_NAME)

$(EXEC) : $(OBJFOLDER) $(ML_OBJS_DST) $(ML_LIBS) $(MK_NAME)
	@$(call echo_in_colors, "\n<linking $(EXEC) with objects $(ML_OBJS_DST) $(PREBUILT_OBJS) and libraries $(ML_LIBS)\n")
	$(LINK) $(PRE_LFLAGS) $(ML_OBJS_DST) -o $(EXEC) $(LFLAGS) $(LLIBS) $(ML_LIBS) $(LLIBS) $(LRPATH) 

$(OBJFOLDER) : 
	@$(call echo_in_colors, "\n<creating object's folder 'obj/'>\n")
	mkdir obj

$(ML_OBJS_DST) : $(OBJFOLDER)/%.c.o : %.c $(MK_NAME)
	@$(call echo_in_colors, "\n<compile $< to $(OBJFOLDER)/$(notdir $@)>\n")
	$(COMP) $(ANDROID_INCLUDES) $(KERNEL_INCLUDES) $(MLSDK_INCLUDES) $(CFLAGS) -o $@ -c $<

clean : 
	rm -fR $(OBJFOLDER)

cleanall : 
	rm -fR $(EXEC) $(OBJFOLDER)

install : $(EXEC)
	cp -f $(EXEC) $(INSTALL_DIR)
