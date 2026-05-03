ROOT_DIR := $(notdir $(CURDIR))
ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

HOST_MKIFS := mkifs
HOST_MKI := mki
HOST_SED := sed
SUFFIXES := .build .bin .raw .ui

# NOTE: This value must match the '[image=<start_addr>]' value in the build file.
IMAGE_LOAD_ADDR = 0x80000

BUILD_TEMPLATE = $(CURDIR)/../../Templates_build_sdp800
BOARD=rpi4
INSTALL=../install

export ARCH = aarch64le
export PROCESSOR = aarch64le

.PHONY: all clean

#all: ifs-$(BOARD).bin ifs-$(BOARD).ui
all: ifs-$(BOARD).bin ifs-$(BOARD)-hyp.bin disk.img

# to boot QNX ifs-rpi4.bin IFS image, add "kernel=ifs-rpi4.bin" to bootable microSD card config.txt file.
ifs-$(BOARD).bin: $(BOARD).build
	$(HOST_MKIFS) -v -r$(INSTALL) $(MKIFSFLAGS) $^ $@

ifs-$(BOARD).raw: $(BOARD).build
	$(CP_HOST) $(BOARD).build $(BOARD)-go.build
	$(HOST_SED) -i 's/u reg/u arg/' $(BOARD)-go.build
	$(HOST_MKIFS) -v -r$(INSTALL) $(MKIFSFLAGS)  $(BOARD)-go.build $@
	$(RM_HOST) $(BOARD)-go.build

# To boot from U-boot "bootm" command:
#  - load ifs-rpi4.ui IFS image to 0x80000
#  - load bcm2711-rpi-4-b.dtb to ${fdt_addr}
#  - run "bootm 0x80000 - ${fdt_addr}"
ifs-$(BOARD).ui: ifs-$(BOARD).bin
	$(HOST_MKI) -a $(IMAGE_LOAD_ADDR) -A arm64 $^ $@
	
# Hypervisor (Hyp) Image Target
ifs-$(BOARD)-hyp.bin: $(BOARD)-hypervisor.build
	$(HOST_MKIFS) -v -r$(INSTALL) $(MKIFSFLAGS) $^ $@

clean:
	$(RM_HOST) ifs-$(BOARD).* *.sym
	$(RM_HOST) ifs-$(BOARD)-hyp.* *.sym
	$(RM_HOST) disk.img part_qnx_data.img part_dos_boot.img

# If the hypervisor boot image variant exists, it will be included in the
# disk image below.
part_dos_boot.img: part_dos_boot.build ifs-$(BOARD)-hyp.bin
	# Create the DOS partition image for UEFI boot mode
	mkfatfsimg  -vv $< $@

part_qnx_data.img: part_qnx_data.build
	# Create the QNX6 partition image for data storage
	mkqnx6fsimg -vv $< $@

disk_image: disk.img
disk.img: disk.cfg part_qnx_data.img part_dos_boot.img
	# Create the boot disk image
	# diskimage -o $@ -c $< -s 131072
	diskimage -o $@ -c $<

-include $(BUILD_TEMPLATE)/template.mk
