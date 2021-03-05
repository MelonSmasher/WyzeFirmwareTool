# Wyze Firmware Tool

A simple tool to handle some mundane tasks that are required when modifying Wyze camera firmware.

## What does it do?

This tool downloads, unpacks, mods, and repacks Wyze firmware files.

## You'll shoot your eye out kid!

A serious heads up! Modifying firmware and flashing modified firmware on your device can brick it.
That means you could be holding a $25 - $100 paperweight if something goes wrong!
Please consider the risks before proceeding!

**I'm NOT responsible if your device turns into an overpriced rock, lights on fire, or anything in between!**

## Camera Support

* Wyze Cam v2

I only have a Wyze Cam v2 to mess around with. If you have a device you're willing to potentially brick feel free to
mess around with this.

## Mods

Below are the mods this tool will enable

* The `-u` / `--usb-ethernet` switch enables USB ethernet adapter support for ASIX based adapters such as [this one](https://www.amazon.com/gp/product/B0863YJB8W/).
* The `-d` / `--disable-wlan` switch disables wireless on the camera. This switch implies the `-u` switch and enables USB ethernet.
* The `-t` / `--telnet-server` switch enables a persistent telnet server on the camera. This option requires that you set a root password, you'll be prompted.
* Custom user supplied mods. The tool will pause to allow you to make any custom modifications tht you'd like. The tool will resume when any key is pressed in the terminal. This step can be skipped with the `-y` / `--no-extra-mods` switch.

More to come!

# Pre-Built Firmware

Since the default root password is well known, I will not be building firmware with telnet enabled.
If you'd like to enable telnet check out the section below on *Generating Your Own Firmware*.

Check out the [releases page](https://github.com/MelonSmasher/WyzeFirmwareTool/releases) for pre-built firmware.

# Generate Your Own Firmware

## Setup

I've only tested this on Ubuntu 20.

### System Prerequisites

Install the following with your package manager:

* python3
* pip
* u-boot-tools
* mtd-utils

### Install

```bash
git clone https://github.com/MelonSmasher/WyzeFirmwareTool.git
pip install -r requirements.txt
```

### Usage

This program requires sudo to manage the JFFS2 image.

#### Modify a specific firmware version

Pick a version number
from [this page](https://wyzelabs.zendesk.com/hc/en-us/articles/360024852172-Release-Notes-Firmware).

```bash
sudo ./wyzefwtool -f <firmware-version>
# E.G: sudo ./wyzefwtool -f 4.9.6.218
```

#### Modify the RTSP firmware

To modify the [official RTSP firmware](https://wyzelabs.zendesk.com/hc/en-us/articles/360026245231-Wyze-Cam-RTSP), run
the following:

```bash
sudo ./wyzefwtool -r
```

#### All command options

```bash
usage: wyzefwtool [-h] [-f [FIRMWARE_VERSION]] [-r] [-u] [-d] [-t] [-y]

optional arguments:
  -h, --help            show this help message and exit
  -f [FIRMWARE_VERSION], --firmware-version [FIRMWARE_VERSION]
                        The version number of the firmware to modify
  -r, --rtsp            Download the RTSP firmware. If used the Firmware Version argument is ignored.
  -u, --usb-ethernet    Enable USB Ethernet support for ASIX based ethernet adapters.
  -d, --disable-wlan    Disabled the wifi connection. Requires that you enable USB ethernet support.
  -t, --telnet-server   Enable persistent telnet server on the camera. Requires that you set a root password.
  -y, --no-extra-mods   The tool will not wait for you to make extra custom modifications.
```
