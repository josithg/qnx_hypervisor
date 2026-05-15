# Getting started with Hypervisor 8.0 on Raspberry Pi 4

This README contains instructions for booting up QNX Hypervisor 8.0 on Raspberry Pi 4 (RPi4) with support for networking, input (mouse, keyboard), and graphics.

1. [Before You Begin](#before-you-begin)
2. [Building QNX Hypervisor](#building-qnx-hypervisor)
    - [Prepare QNX Hypervisor Build File](#prepare-qnx-hypervisor-build-file)
    - [Configure Hypervisor Guests](#configure-hypervisor-guests)
    - [Prepare QNX Hypervisor Disk Image](#prepare-qnx-hypervisor-disk-image)
3. [Booting QNX Hypervisor](#booting-qnx-hypervisor)
    - [Starting a QNX Guest](#starting-a-qnx-guest)
    - [Starting a Linux Guest](#starting-a-linux-guest)
    - [Shutting Down Guests / Host](#shutting-down-guests--host)

## Before You Begin
This guide assumes that you have already installed SDP 8.0 and the Raspberry Pi 4 BSP file from QNX Software Center (QSC). (For information about how to get a free QNX license and install the QNX Software Development Platform, see the [QNX Everywhere documentation](https://www.qnx.com/developers/docs/qnxeverywhere/com.qnx.doc.qnxeverywhere/topic/qsti/install.html).) The Pi 4 BSP package name is `com.qnx.qnx800.bsp.hw.raspberrypi_bcm2711_rpi4`.

Find the BSP package, typically in `~/qnx800/bsp`, and extract it. This is your *Pi 4 BSP directory*, referenced often below.

> The QNX Everywhere license (perpetual non-commercial) includes an entitlement to QNX Hypervisor 8.0. If you are using a different license type, reach out to your QNX contact for information about your license and entitlements.

1. Install the following Hypervisor packages from the QNX Software Center (QSC):
    - QNX Hypervisor 8.0: com.qnx.qnx800.target.hypervisor.group
    - QNX® SDP 8.0 BSP for Hypervisor guest for generic ARM virtual machines: com.qnx.qnx800.bsp.hypervisor_guest_arm
2. To enable input (mouse, keyboard), install the following from QSC:
    - QNX® SDP 8.0 Device Input - HID Drivers: com.qnx.qnx800.target.input.devh
    - QNX® SDP 8.0 Device Input - Keyboard: com.qnx.qnx800.target.input.keyboard
3. To enable graphics, install the following from QSC:
    - QNX® SDP 8.0 Raspberry Pi Screen board support (and all dependencies): com.qnx.qnx800.target.screen.board.rpi
    - QNX® SDP 8.0 Screen Board Support Raspberry Pi 4: com.qnx.qnx800.target.screen.board.rpi4
    - QNX® SDP 8.0 Screen Base Graphics: com.qnx.qnx800.target.screen.base
    - QNX® SDP 8.0 Common Mesa: com.qnx.qnx800.target.screen.board.common_mesa
    - QNX® SDP 8.0 Server supporting Broadcom GPUs on Raspberry Pi 4 and 5: com.qnx.qnx800.target.screen.board.rpi.mesa
    - QNX® SDP 8.0 Mesa3D drivers for Broadcom GPUs on Raspberry Pi 4 and 5: com.qnx.qnx800.target.screen.board.rpi.server
    - QNX® SDP 8.0 Common DRM utilities for Screen board support: com.qnx.qnx800.target.screen.board.common_drm
    - QNX® SDP 8.0 Screen Graphics Demo/Sample Applications - com.qnx.qnx800.target.screen.demos

## Building QNX Hypervisor

### Prepare QNX Hypervisor Build File
At this time, the QNX-supplied Pi 4 BSP does not include a hypervisor build file variant.

To build a Hypervisor image for Pi 4, you must modify the existing QNX SDP 8.0 Pi 4 build file to enable QNX Hypervisor. Refer to [this documentation](https://www.qnx.com/developers/docs/8.0/com.qnx.doc.hypervisor.user/topic/build/build_host.html#build_host.xml__build_without_variant) for more details.

The required build file modifications include:
- Add `-Q enable,el1-host` flag to enable `startup-bcm2711-rpi4` with Hypervisor
- Add Hypervisor-specific binaries, utilities, and libraries
- Add Pi 4-specific graphics binaries and screen demos
- Add Human-Interface Device (HID) binaries and drivers to enable input

A sample Pi 4 Hypervisor build file with these changes is included in this repo ([rpi4-hypervisor.build](rpi4-hypervisor.build)). This build file should be placed in the `images/` folder of your Pi 4 BSP directory.

> In the above configuration we are running the hypervisor host in EL1 (non-VHE). The QNX Hypervisor supports VHE mode (el2-host) but there are limitations with the VHE-enabled subsystems on the Pi 4. Therefore, we are running in non-VHE on this hardware.

### Configure Hypervisor Guests

The QNX Hypervisor image runs on your target, and it supports one or more virtualized "guest" operating systems. These can be QNX guests, Linux guests, or other specific-purpose guests.

#### QNX Guests

To launch a QNX guest, you will need a QNX IFS image and qvm configuration file.

##### Build QNX Guest
You can retrieve sample QNX guest build files and configuration files from the QNX® SDP 8.0 BSP for Hypervisor guest for generic ARM virtual machines package (which you installed from QSC). Look in your local SDP installation (`~/qnx800/bsp/` by default).

1.	Unzip this Hypervisor guest BSP package into a new directory (ex: `hypervisor_guest_bsp`).
2.	Navigate to the `hypervisor_guest_bsp/` directory.
3.	Run `make` to build the BSP.

Your `hypervisor_guest_bsp/images/` directory will now contain the following:

```bash
├── common-definitions.m4
├── common.mk
├── guest-1
│   ├── definitions.m4
│   ├── Makefile
│   ├── procnto-smp-instr.qnx800-guest-1.sym
│   ├── qnx800-guest-1.build
│   ├── qnx800-guest-1.ifs
│   ├── qnx800-guest-1.qvmconf
│   └── startup-armv8_fm.qnx800-guest-1.sym
├── guest-2
│   ├── definitions.m4
│   ├── Makefile
│   ├── procnto-smp-instr.qnx800-guest-2.sym
│   ├── qnx800-guest-2.build
│   ├── qnx800-guest-2.ifs
│   ├── qnx800-guest-2.qvmconf
│   └── startup-armv8_fm.qnx800-guest-2.sym
└── Makefile
```

##### Configure QNX Guest

Navigate to your Pi 4 BSP directory.

Within the `images/` folder of your Pi 4 BSP directory, create a `guests/` directory. Inside `guests/`, create a directory `qnx-guest/`. Place the following files within this directory:
- the QNX IFS image from `guest-1/` above (ex: `qnx800-guest-1.ifs`)
- the QNX guest configuration file  from `guest-1/` above (ex: `qnx800-guest-1.qvmconf`)

#### Linux Guest
To launch a Linux guest, you will need a Linux kernel image and qvm configuration file. See [this repo](https://gitlab.com/qnx/hypervisor/working-with-guests/linux) for an example `qvmconf` file, and [this repo](https://gitlab.com/qnx/hypervisor/yocto/build) for build scripts and configuration files for Yocto/Poky reference images for QNX.

Within the `images/` directory of your Pi 4 BSP directory, create a `guests/linux-guest/` directory. Place the following files within this folder:
- image
- rootfs files
- Linux guest configuration file

### Prepare QNX Hypervisor Disk Image

To boot QNX Hypervisor on the Pi 4, you will need to build a Hypervisor disk image.

#### Create Disk Partitions

This disk image must include the Hypervisor host in a DOS partition and the Hypervisor guests in a QNX6FS data partition. Refer to [this documentation](https://www.qnx.com/developers/docs/8.0/com.qnx.doc.hypervisor.user/topic/build/create_image.html) for more details.

Sample partition build files are included in this repo in [/sample-partition-files](/sample-partition-files/).
- `disk.cfg`
- `part_dos_boot.build`
- `part_qnx_data.build`

These files should be placed in the `/images` folder of your Pi 4 BSP directory.

#### Transfer Firmware Files
The `images/` folder should contain [all required Pi 4 firmware files](https://github.com/raspberrypi/firmware/tree/stable/boot) (`bcm2711-rpi-4-b.dtb`, `overlays/`, `start4.elf`, `fixup4.dat`).

#### Build Disk Image
Modify the `Makefile` in the `images/` directory to include steps to build the Hypervisor IFS and disk image targets.

A sample modified Makefile is included in this repo ([Makefile](Makefile)).

From the main Pi 4 BSP directory, run `make`. Find `disk.img` inside `images/` when the build is complete.

#### Transfer Disk Image
Refer to [this documentation](https://www.qnx.com/developers/docs/8.0/com.qnx.doc.hypervisor.user/topic/build/transfer.html) for how to transfer your disk image to a micro SD card. You can also [use the Raspberry Pi Imager](https://www.qnx.com/developers/docs/qnxeverywhere/com.qnx.doc.qnxeverywhere/topic/qsti/install.html#ariaid-title3). 

```bash
sudo dd if=disk.img of=/dev/sda bs=1024k status=progress
5968494592 bytes (6.0 GB, 5.6 GiB) copied, 411 s, 14.5 MB/s
1425+0 records in
1425+0 records out
5976883200 bytes (6.0 GB, 5.6 GiB) copied, 411.763 s, 14.5 MB/s

# Ensure all data is written
sync
```

## Booting QNX Hypervisor
1. Insert the SD card with your Hypervisor image into the slot on the board.
2. Use the Raspberry Pi Debug Probe cable to connect the board’s UART port to the USB port on your host machine. Open a connection to `/dev/ttyACMX` using PuTTY, screen, or similar.
3. Connect an Ethernet cable to the Ethernet port on the board.
4. Connect an HDMI display to the HDMI0 port on the board.

> All screen-related libraries, drivers, and parameters are set using a `graphics.conf` file. The QNX® SDP 8.0 Raspberry Pi Screen board support contains sample configuration files.
> This guide uses `graphics-rpi4.conf`, which uses the first HDMI port (HDMI0) on the Pi 4.

5. Connect the power supply cable to the power port on the board. 

You should see the following boot logs through your UART serial connection:

```bash
Enabling EL1 host hypervisor support

...

Welcome to QNX 8.0.0 on RaspberryPi4B !
 
Starting wdtkick ...
Starting I2C driver ...
Starting PCI Server ...
Starting serial driver (/dev/ser1)
Starting SPI master driver ...
Starting SDMMC driver (/dev/sd0)
Path=0 - bcm2711
 target=0 lun=0     Direct-Access(0) - SDMMC: SR128 Rev: 8.7
Inform vc to load vl805 firmware
Starting USB xHCI controller in the host mode (/dev/usb/*)...
Mounting /dev/sd0t179 on / ...
Starting networking ...
Creating example ram disks for guests to use
Path=0 - 
 target=0 lun=0     Direct-Access(0) - ram  Rev: 
net.link.bridge.inherit_mac: 0 -> 1
Starting DHCP client ...
Starting SSH daemon ...
Starting devc-pty manager ...
Starting qconn daemon ...
Starting board customize script ...
Running user's startup script ...
Starting shell ...
```

To enable input via USB mouse/keyboard, start the HID driver on the QNX Host: `io-hid -dusb`

To enable graphics, start `screen` and load the graphics configuration file: `screen -c /usr/lib/graphics/rpi4-drm/graphics-rpi4.conf`

If it is successful, your connected display will power on.

To verify graphics functionality, use the following graphics demo: `gles2-gears`

### Starting a QNX Guest
1. Navigate to qnx-guest directory: `cd /guests/qnx-guest`
2. Launch QNX guest: `qvm @qnx800-guest-1.qvmconf`
3. Verify the QNX guest console logs:

```bash
Welcome to QNX 8.0.0 on ARMv8_Foundation_Model !
 
Starting devf-ram filesystem ...
Starting networking ...
Starting DHCP client ...
Starting SSH daemon ...
Starting devc-pty manager ...
Starting qconn daemon ...
Virtual networking comes up by default if virtio-net devices are configured for this guest

A virtual block device can be started by running /scripts/block-start.sh
   (this requires vdev-virtio-blk is configured for this guest)
   (Note that it assumes you are using a blank RAM disk as host device)

Virtual shared memory device demo driver can be started by running /scripts/shmem-start.sh
   (this requires vdev-shmem is configured in this guest)

Virtual watchdog device can be started and stopped by running /scripts/watchdog-start.sh and watchdog-stop.sh
   (this requires a vdev-wdt-* is configured in this guest)

Note: the scripts above assume that you have located your virtual devices at particular loc/intr values
      that match the values passed to the corresponding driver

Starting shell ...
[armv8 guest QNX 8.x guest 1]%
```
credits: [john@qnx_gitlab](https://gitlab.com/qnx/hypervisor/getting-started)
