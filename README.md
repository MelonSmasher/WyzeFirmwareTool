# Wyze Firmware Tool

A simple tool to handle some mundane tasks that are required when modifying Wyze camera firmware.

## What does it do?

This tool downloads, unpacks, and repacks Wyze firmware files.

At this time it does NOT make any changes to the firmware.

## Camera Support

* Wyze Cam v2

I only have a Wyze Cam v2 to mess around with. If you have a device you're willing to potentially brick feel free to mess around with this.

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

#### Modify a specific firmware version

Pick a version number from [this page](https://wyzelabs.zendesk.com/hc/en-us/articles/360024852172-Release-Notes-Firmware).

```bash
./wyzefwtool -f <firmware-version>
# E.G: ./wyzefwtool -f 4.9.6.218
```

#### Modify the RTSP firmware

To modify the [official RTSP firmware](https://wyzelabs.zendesk.com/hc/en-us/articles/360026245231-Wyze-Cam-RTSP), run the following:

```bash
./wyzefwtool -r
```

---

Thanks to [jlegarreta](https://github.com/jlegarreta) for the [JFFS2 mount/unmount scripts](jlegarreta/mount.jffs2)!
