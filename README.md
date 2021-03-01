# Wyze Firmware Tool

A simple tool to handle some mundane tasks that are required when modifying Wyze camera firmware.

## What does it do?

This tool downloads, unpacks, and repacks Wyze firmware files.

## Camera Support

* Wyze Cam v2

I only have a Wyze Cam v2 to mess around with. If you have a device you're willing to potentially brick feel free to
mess around with this.

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
usage: wyzefwtool [-h] [-f [FIRMWARE_VERSION]] [-r] [-u] [-t]

optional arguments:
  -h, --help            show this help message and exit
  -f [FIRMWARE_VERSION], --firmware-version [FIRMWARE_VERSION]
                        The version number of the firmware to modify
  -r, --rtsp            Download the RTSP firmware. If used the Firmware Version argument is ignored.
  -u, --usb-ethernet    Enable USB Ethernet support for ASIX based ethernet adapters.
  -t, --telnet-server   Enable persistent telnet server on the camera.
```
