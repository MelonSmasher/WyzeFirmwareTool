from urllib.parse import urlparse
from fwtool.models import FirmwarePart
from fwtool.mods import enable_usbnet, enable_telnet
import os
import requests
import zipfile
import pathlib
import shutil
import subprocess
import time
import sys


def download_firmware(version='4.9.6.218', rtsp=False):
    print('######################################')
    print('Obtaining firmware from Wyze')
    print('######################################')
    # Determine the URL
    url = 'https://download.wyzecam.com/firmware/v2/demo_' + version + '.bin.zip'
    if rtsp:
        url = 'https://download.wyzecam.com/firmware/rtsp/demo_v2_rtsp_4.28.4.49.bin.zip'
    # Parse the URL into parts
    url_parsed = urlparse(url)
    # Create a file path
    file = os.path.join('firmware', 'zips', os.path.basename(url_parsed.path))
    print('Downloading ' + url + ' ---> ' + file, end=' ... ')
    # Get the URL content
    response = requests.get(url, allow_redirects=True)
    # Save the request response content as the file
    open(file, 'wb').write(response.content)
    print('Done!')
    # Return the downloaded file path
    return file


def unzip_firmware(zip_path):
    print()
    print('######################################')
    print('Unzipping firmware bin')
    print('######################################')
    # Build the output dir
    out_dir = os.path.join('firmware', 'bins')
    # Get the name of the bin file
    out_file = os.path.splitext(os.path.basename(zip_path))[0]
    # Build the full output path
    out_path = os.path.join(out_dir, out_file)
    # Start the unzip
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        print('Downloading ' + zip_path + ' ---> ' + out_path, end='... ')
        # Unzip the file
        zip_ref.extractall(out_dir)
    print('Done!')
    # Return the bin path
    return out_path


def unpack_bin(bin_path):
    # Get the base name of the dir we'll unpack to
    dir_name = os.path.splitext(os.path.basename(bin_path))[0]
    # Build the path to the dir we'll unpack to
    unpack_dir = os.path.join('firmware', 'unpacked', dir_name)
    # Build the parts dir
    parts_dir = os.path.join(unpack_dir, 'parts')
    # Start fresh by deleting the directory if it exists
    shutil.rmtree(unpack_dir, ignore_errors=True)
    # Create the directory
    pathlib.Path(parts_dir).mkdir(parents=True, exist_ok=True)
    # Define our firmware parts
    firmware_parts = [
        FirmwarePart("uimage_header", 0x0, 0x40),
        FirmwarePart("uimage_kernel", 0x40, 0x200000),
        FirmwarePart("squashfs_1", 0x200040, 0x350000),
        FirmwarePart("squashfs_2", 0x550040, 0xa0000),
        FirmwarePart("jffs2", 0x5f0040, 11075648 - 0x5f0040)
    ]
    print('')
    print('######################################')
    print('Unpacking firmware bin')
    print('######################################')
    # Open the bin file
    fw_bin = open(bin_path, "rb")
    # Split the firmware file into different parts
    for part in firmware_parts:
        outfile_path = os.path.join(parts_dir, part.name)
        outfile = open(outfile_path, "wb")
        fw_bin.seek(part.offset, 0)
        data = fw_bin.read(part.size)
        outfile.write(data)
        outfile.close()
        print(f"Wrote {part.name} - {hex(len(data))} bytes")
        # If we just split out a squashfs lets inflate it
        if part.name in ['squashfs_1', 'squashfs_2']:
            __unsquash(unpack_dir, outfile_path)
        if part.name in ['jffs2']:
            # Mount unpack_dir/jffs2
            __mount_jffs2(unpack_dir, outfile_path)
    # Return the directory with the parts
    return unpack_dir


def run_mods(unpack_dir, usb_eth=False, telnet=False):
    squashfs_1 = os.path.join(unpack_dir, 'squashfs_1')
    squashfs_2 = os.path.join(unpack_dir, 'squashfs_2')
    jffs2 = os.path.join(unpack_dir, 'jffs2')

    if usb_eth:
        enable_usbnet(squashfs_2, jffs2)
    if telnet:
        enable_telnet(os.path.join(squashfs_1, 'etc', 'init.d', 'rcS'))


def wait_for_mods(unpack_dir):
    print('')
    print('######################################')
    print('Time for your mods!')
    print('######################################')
    print('Make changes to the following directories:')
    print('* ' + os.path.join(unpack_dir, 'squashfs_1'))
    print('* ' + os.path.join(unpack_dir, 'squashfs_2'))
    print('* ' + os.path.join(unpack_dir, 'jffs2'))
    print('Changes to those directories will be packed into your firmware image')
    print('Press any key to pack your mods...')
    print()
    result = None
    if os.name == 'nt':
        import msvcrt
        result = msvcrt.getch()
    else:
        import termios
        fd = sys.stdin.fileno()

        oldterm = termios.tcgetattr(fd)
        newattr = termios.tcgetattr(fd)
        newattr[3] = newattr[3] & ~termios.ICANON & ~termios.ECHO
        termios.tcsetattr(fd, termios.TCSANOW, newattr)

        try:
            result = sys.stdin.read(1)
        except IOError:
            pass
        finally:
            termios.tcsetattr(fd, termios.TCSAFLUSH, oldterm)

    return result


def pack_bin(unpack_dir):
    # Create a directory to have our working parts to pack
    scratch_dir = os.path.join(unpack_dir, 'scratch')
    pathlib.Path(scratch_dir).mkdir(parents=True, exist_ok=True)
    # Build the parts dir
    parts_dir = os.path.join(unpack_dir, 'parts')
    # Build the bin name
    bin_name = os.path.basename(unpack_dir)
    # The intermediate bin path
    intermediate_bin_path = os.path.join(scratch_dir, bin_name)
    # Final bin path
    final_bin_name = bin_name + '_modded_' + str(int(time.time())) + '.bin'
    final_bin_path = os.path.join('firmware', 'bins', final_bin_name)
    # Define our firmware parts
    firmware_parts = [
        FirmwarePart("uimage_header", 0x0, 0x40),
        FirmwarePart("uimage_kernel", 0x40, 0x200000),
        FirmwarePart("squashfs_1", 0x200040, 0x350000),
        FirmwarePart("squashfs_2", 0x550040, 0xa0000),
        FirmwarePart("jffs2", 0x5f0040, 11075648 - 0x5f0040)
    ]
    print('')
    print('######################################')
    print('Packing intermediate bin')
    print('######################################')
    # Open the intermediate bin file
    intermediate_bin = open(intermediate_bin_path, "wb")
    for part in firmware_parts[1:]:
        # Build the part_name var
        part_name = part.name
        # If the part is a squash
        if part.name in ['squashfs_1', 'squashfs_2']:
            # Reassign the part name with the '_new' suffix
            part_name = part_name + '_new'
            # Create the new squash
            __squash(unpack_dir, part.name)
        # If the part is JFFS2
        if part.name in ['jffs2']:
            # Reassign the part name with the '_new' suffix
            part_name = part_name + '_new'
            # Unmount the JFFS2 image
            __unmount_jffs2(unpack_dir)
        part_file = open(os.path.join(parts_dir, part_name), "rb")
        data = part_file.read()
        intermediate_bin.write(data)
        padding = (part.size - len(data))
        print(f"Wrote {part_name} - {hex(len(data))} bytes")
        print(f"Padding: {hex(padding)}")
        intermediate_bin.write(b'\x00' * padding)
    print('Intermediate bin packed at: ')
    print(intermediate_bin_path)

    print('')
    print('######################################')
    print('Packing firmware bin: ' + final_bin_name)
    print('######################################')
    # Make the firmware bin
    subprocess.run([
        'mkimage',
        '-A',
        'MIPS',
        '-O',
        'linux',
        '-T',
        'firmware',
        '-C',
        'none',
        '-a',
        '0',
        '-e',
        '0',
        '-n',
        'jz_fw',
        '-d',
        intermediate_bin_path,
        final_bin_path
    ], stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    time.sleep(2)
    while not os.path.exists(final_bin_path):
        time.sleep(1)
    print('New modded firmware file has been written to: ')
    print(final_bin_path)


def __get_fw_parts():
    # Define our firmware parts
    return [
        FirmwarePart("uimage_header", 0x0, 0x40),
        FirmwarePart("uimage_kernel", 0x40, 0x200000),
        FirmwarePart("squashfs_1", 0x200040, 0x350000),
        FirmwarePart("squashfs_2", 0x550040, 0xa0000),
        FirmwarePart("jffs2", 0x5f0040, 11075648 - 0x5f0040)
    ]


def __mount_jffs2(unpack_dir, jffs2_path):
    # Copy the jffs2 file to jffs2_new
    shutil.copyfile(jffs2_path, jffs2_path + '_new')
    # The path of the file to mount
    mount_file = jffs2_path + '_new'
    # Build the dir path to mount to
    mount_dir = os.path.join(unpack_dir, os.path.basename(jffs2_path))
    print('Mounting ' + mount_file + ' at ' + mount_dir, end=' ... ')
    pathlib.Path(mount_dir).mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ['sudo', 'support/scripts/mount.jffs2.sh', mount_file, mount_dir],
    )
    print('Done!')


def __unmount_jffs2(unpack_dir):
    mount_dir = os.path.join(unpack_dir, 'jffs2')
    print('Unmounting ' + mount_dir, end=' ... ')
    subprocess.run(
        ['sudo', 'support/scripts/umount.jffs2.sh', mount_dir],
    )
    print('Done!')


def __unsquash(unpack_dir, squashfs_path):
    # Get the base file name
    squashfs_name = os.path.basename(squashfs_path)
    # Build the dir path to extract to
    squashfs_dir = os.path.join(unpack_dir, squashfs_name)
    print('Unsquashing ' + squashfs_path, end=' ... ')
    # Extract the squashfs file
    # @todo If possible, replace the subprocess call with a native python method to inflate squashfs systems
    subprocess.run(
        ['unsquashfs', '-d', squashfs_dir, squashfs_path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT
    )
    time.sleep(2)
    while not os.path.exists(squashfs_dir):
        time.sleep(1)
    print('Done!')


def __squash(unpack_dir, squashfs_name):
    # Build the dir path to squash
    squashfs_dir = os.path.join(unpack_dir, squashfs_name)
    # Build the dir path to squash
    squashfs_new_file = os.path.join(unpack_dir, 'parts', squashfs_name + '_new')
    print('Squashing ' + squashfs_new_file, end=' ... ')
    # Pack the squashfs file
    # @todo If possible, replace the subprocess call with a native python method to pack squashfs systems
    subprocess.run(
        ['mksquashfs', squashfs_dir, squashfs_new_file, '-comp', 'xz', '-b', '131072'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT
    )
    time.sleep(2)
    while not os.path.exists(squashfs_new_file):
        time.sleep(1)
    print('Done!')
